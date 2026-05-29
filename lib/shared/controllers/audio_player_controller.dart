import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:riftwave_music/core/audio/audio_handler.dart';
import 'package:riftwave_music/core/audio/repeat_mode.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/lastfm_api.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/features/player/controllers/dynamic_color_controller.dart';
import 'package:riftwave_music/core/services/recommendation_engine.dart';
import 'package:riftwave_music/shared/controllers/video_player_controller.dart';

class AudioPlayerController extends GetxController {
  late final RiftWaveAudioHandler _audioHandler;

  final Rx<SongModel?> currentSong = Rx<SongModel?>(null);
  final RxBool hasSong = false.obs;

  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final Rx<Duration> bufferedPosition = Duration.zero.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  final RxList<SongModel> queue = <SongModel>[].obs;
  final RxInt currentQueueIndex = (-1).obs;

  final RxBool shuffleMode = false.obs;
  final Rx<RiftWaveRepeatMode> repeatMode = RiftWaveRepeatMode.off.obs;

  final RxString errorMessage = ''.obs;

  final Rx<Duration?> sleepTimerRemaining = Rx<Duration?>(null);
  Timer? _sleepTimer;
  final RxDouble volume = 1.0.obs;

  List<int> _shuffledIndices = [];
  int _shufflePosition = 0;
  String _lastColorUrl = '';

  final List<StreamSubscription> _subscriptions = [];

  static const String _queueBoxName = 'queue_box';

  final RxList<SongModel> upNextSuggestions = <SongModel>[].obs;
  String _lastSuggestionSongId = '';

  @override
  void onInit() {
    super.onInit();
    _audioHandler = Get.find<RiftWaveAudioHandler>();
    _audioHandler.onPlaybackCompleted = _onTrackCompleted;
    _audioHandler.onSkipToNextCallback = () => skipToNext();
    _audioHandler.onSkipToPreviousCallback = () => skipToPrevious();
    _listenToStreams();
    _restoreQueue();
    _requestNotificationPermission();

    ever<SongModel?>(currentSong, (song) {
      if (song != null && song.thumbnailUrl.isNotEmpty && song.thumbnailUrl != _lastColorUrl) {
        _lastColorUrl = song.thumbnailUrl;
        if (Get.isRegistered<DynamicColorController>()) {
          Get.find<DynamicColorController>().extractFromImageUrl(song.thumbnailUrl);
        }
      }
      if (song != null && song.id != _lastSuggestionSongId) {
        _lastSuggestionSongId = song.id;
        _refreshUpNextSuggestions(song);
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Future.delayed(const Duration(seconds: 2));
        if (Get.context != null) {
          final theme = Theme.of(Get.context!);
          final colorScheme = theme.colorScheme;
          
          final shouldRequest = await showDialog<bool>(
            context: Get.context!,
            builder: (context) => AlertDialog(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              icon: Icon(Icons.notifications_active_rounded, size: 48, color: colorScheme.primary),
              title: Text(
                'Enable Notifications',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'RiftWave needs notification permission to show playback controls on your lock screen, status bar, and Dynamic Island.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(180)),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Not Now', style: TextStyle(color: colorScheme.onSurface.withAlpha(150))),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Allow'),
                ),
              ],
            ),
          );
          if (shouldRequest == true) {
            final result = await Permission.notification.request();
            debugPrint('AudioPlayerController: Notification permission result: $result');
          }
        }
      }
    } catch (e) {
      debugPrint('AudioPlayerController: Failed to request notification permission: $e');
    }
  }

  Uri? _getHighResArtUri(SongModel song) {
    if (song.thumbnailUrl.isEmpty) return null;
    String artUrl = song.thumbnailUrl;
    if (song.source == MusicSource.youtube) {
      final videoId = song.sourceId.isNotEmpty ? song.sourceId : song.id;
      artUrl = YouTubeApi.getMaxResThumbnail(videoId);
    } else if (song.source == MusicSource.saavn) {
      artUrl = artUrl.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');
    }
    return Uri.tryParse(artUrl);
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _sleepTimer?.cancel();
    super.onClose();
  }

  void _listenToStreams() {
    _subscriptions.add(
      _audioHandler.playerStateStream.listen((PlayerState state) {
        isPlaying.value = state.playing;
        isBuffering.value =
            state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;
      }),
    );

    _subscriptions.add(
      _audioHandler.positionStream.listen((Duration pos) {
        currentPosition.value = pos;
      }),
    );

    _subscriptions.add(
      _audioHandler.bufferedPositionStream.listen((Duration pos) {
        bufferedPosition.value = pos;
      }),
    );

    _subscriptions.add(
      _audioHandler.durationStream.listen((Duration? dur) {
        if (dur != null) {
          totalDuration.value = dur;
        }
      }),
    );
  }

  Future<void> playSong(SongModel song) async {
    queue.assignAll([song]);
    currentQueueIndex.value = 0;
    _resetShuffleIndices();
    await _loadAndPlay(song);
    _persistQueue();
  }

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= queue.length) return;
    currentQueueIndex.value = index;

    if (shuffleMode.value) {
      _shufflePosition = _shuffledIndices.indexOf(index);
      if (_shufflePosition == -1) _shufflePosition = 0;
    }

    await _loadAndPlay(queue[index]);
  }

  Future<void> togglePlayPause() async {
    if (!hasSong.value) return;
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play({bool forceInternal = false}) async {
    if (!forceInternal && Get.isRegistered<VideoPlayerController>()) {
      final vpc = Get.find<VideoPlayerController>();
      if (vpc.isHandlingPlayback) {
        await vpc.play();
        return;
      }
    }
    await _audioHandler.play();
  }

  Future<void> pause({bool forceInternal = false}) async {
    if (!forceInternal && Get.isRegistered<VideoPlayerController>()) {
      final vpc = Get.find<VideoPlayerController>();
      if (vpc.isHandlingPlayback) {
        await vpc.pause();
        return;
      }
    }
    await _audioHandler.pause();
  }

  Future<void> skipToNext() async {
    if (queue.isEmpty) return;

    final nextIndex = _getNextIndex();
    if (nextIndex == null) {
      await _audioHandler.stop();
      return;
    }

    currentQueueIndex.value = nextIndex;
    await _loadAndPlay(queue[nextIndex]);
    _persistQueue();
  }

  Future<void> skipToPrevious() async {
    if (queue.isEmpty) return;

    if (currentPosition.value.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    final prevIndex = _getPreviousIndex();
    if (prevIndex == null) return;

    currentQueueIndex.value = prevIndex;
    await _loadAndPlay(queue[prevIndex]);
    _persistQueue();
  }

  Future<void> seekTo(Duration position) async {
    if (Get.isRegistered<VideoPlayerController>()) {
      final vpc = Get.find<VideoPlayerController>();
      if (vpc.isHandlingPlayback) {
        await vpc.seek(position);
        return;
      }
    }
    await _audioHandler.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed.value = speed;
    await _audioHandler.setSpeed(speed);
  }

  void addToQueue(SongModel song) {
    queue.add(song);
    _resetShuffleIndices();
    _persistQueue();
  }

  Future<void> playAll(List<SongModel> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    queue.assignAll(songs);
    currentQueueIndex.value = startIndex;
    _resetShuffleIndices();
    await _loadAndPlay(songs[startIndex]);
    _persistQueue();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= queue.length) return;

    final wasPlaying = index == currentQueueIndex.value;
    queue.removeAt(index);

    if (queue.isEmpty) {
      _clearState();
      return;
    }

    if (index < currentQueueIndex.value) {
      currentQueueIndex.value--;
    } else if (wasPlaying) {
      if (currentQueueIndex.value >= queue.length) {
        currentQueueIndex.value = 0;
      }
      _loadAndPlay(queue[currentQueueIndex.value]);
    }

    _resetShuffleIndices();
    _persistQueue();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final song = queue.removeAt(oldIndex);
    queue.insert(newIndex, song);

    if (currentQueueIndex.value == oldIndex) {
      currentQueueIndex.value = newIndex;
    } else if (oldIndex < currentQueueIndex.value &&
        newIndex >= currentQueueIndex.value) {
      currentQueueIndex.value--;
    } else if (oldIndex > currentQueueIndex.value &&
        newIndex <= currentQueueIndex.value) {
      currentQueueIndex.value++;
    }

    _resetShuffleIndices();
    _persistQueue();
  }

  Future<void> clearQueue() async {
    await _audioHandler.stop();
    queue.clear();
    _clearState();
    _persistQueue();
  }

  void toggleShuffle() {
    shuffleMode.value = !shuffleMode.value;
    if (shuffleMode.value) {
      _generateShuffledIndices();
    }
  }

  void cycleRepeatMode() {
    switch (repeatMode.value) {
      case RiftWaveRepeatMode.off:
        repeatMode.value = RiftWaveRepeatMode.all;
        break;
      case RiftWaveRepeatMode.all:
        repeatMode.value = RiftWaveRepeatMode.one;
        break;
      case RiftWaveRepeatMode.one:
        repeatMode.value = RiftWaveRepeatMode.off;
        break;
    }
  }

  double get progress {
    if (totalDuration.value.inMilliseconds == 0) return 0.0;
    return (currentPosition.value.inMilliseconds /
            totalDuration.value.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  bool get hasNext {
    if (queue.isEmpty) return false;
    if (repeatMode.value != RiftWaveRepeatMode.off) return true;
    if (shuffleMode.value) {
      return _shufflePosition < _shuffledIndices.length - 1;
    }
    return currentQueueIndex.value < queue.length - 1;
  }

  bool get hasPrevious {
    if (queue.isEmpty) return false;
    if (repeatMode.value != RiftWaveRepeatMode.off) return true;
    if (shuffleMode.value) {
      return _shufflePosition > 0;
    }
    return currentQueueIndex.value > 0;
  }

  Future<void> _loadAndPlay(SongModel song) async {
    errorMessage.value = '';
    try {
      await _audioHandler.stop();
    } catch (_) {}
    currentSong.value = song;
    hasSong.value = true;

    final remainingInQueue = queue.length - 1 - currentQueueIndex.value;
    if (remainingInQueue < 5) {
      _fetchAndAppendSimilar(song);
    }

    currentPosition.value = Duration.zero;
    totalDuration.value = Duration(milliseconds: song.durationMs);

    SongModel activeSong = song;

    if (activeSong.sourceId.isEmpty) {
      debugPrint('AudioPlayerController: Song sourceId is empty. Resolving via search for: ${activeSong.title} - ${activeSong.artist}');
      try {
        if (activeSong.source == MusicSource.youtube) {
          final searchResults = await Get.find<YouTubeApi>().search('${activeSong.title} ${activeSong.artist}');
          if (searchResults.isNotEmpty) {
            final matched = searchResults.first;
            activeSong = activeSong.copyWith(
              sourceId: matched.sourceId,
              durationMs: matched.durationMs > 0 ? matched.durationMs : activeSong.durationMs,
              thumbnailUrl: (activeSong.thumbnailUrl.isEmpty || activeSong.thumbnailUrl.contains('2a96cbd8b46e442fc41c2b86b821562f'))
                  ? matched.thumbnailUrl
                  : activeSong.thumbnailUrl,
            );
            final idx = queue.indexWhere((s) => s.id == song.id);
            if (idx != -1) {
              queue[idx] = activeSong;
            }
            currentSong.value = activeSong;
            totalDuration.value = Duration(milliseconds: activeSong.durationMs);
          }
        } else {
          final searchResults = await Get.find<SaavnApi>().searchSongs('${activeSong.title} ${activeSong.artist}');
          if (searchResults.isNotEmpty) {
            final matched = searchResults.first;
            activeSong = activeSong.copyWith(
              sourceId: matched.sourceId,
              durationMs: matched.durationMs > 0 ? matched.durationMs : activeSong.durationMs,
              thumbnailUrl: (activeSong.thumbnailUrl.isEmpty || activeSong.thumbnailUrl.contains('2a96cbd8b46e442fc41c2b86b821562f'))
                  ? matched.thumbnailUrl
                  : activeSong.thumbnailUrl,
            );
            final idx = queue.indexWhere((s) => s.id == song.id);
            if (idx != -1) {
              queue[idx] = activeSong;
            }
            currentSong.value = activeSong;
            totalDuration.value = Duration(milliseconds: activeSong.durationMs);
          }
        }
      } catch (e) {
        debugPrint('AudioPlayerController: Failed to pre-resolve empty sourceId: $e');
      }
    }

    String streamUrl = '';
    bool success = false;
    bool isLocal = false;

    if (activeSong.isDownloaded && activeSong.localPath != null) {
      final file = File(activeSong.localPath!);
      if (await file.exists()) {
        streamUrl = Uri.file(activeSong.localPath!).toString();
        isLocal = true;
      }
    }

    if (isLocal) {
      try {
        final mediaItem = MediaItem(
          id: activeSong.id,
          title: activeSong.title,
          artist: activeSong.artist,
          album: activeSong.album,
          duration: Duration(milliseconds: activeSong.durationMs),
          artUri: _getHighResArtUri(activeSong),
        );
        await _audioHandler.setMediaItemAndPlay(mediaItem, streamUrl);
        success = true;
        debugPrint('AudioPlayerController: Playing from local download successfully!');
      } catch (e) {
        debugPrint('AudioPlayerController: Failed to play local file: $e');
        isLocal = false;
      }
    }

    if (!success) {
      try {
        debugPrint('AudioPlayerController: Trying primary source (${activeSong.source.name}) for: ${activeSong.title}');
      if (activeSong.source == MusicSource.youtube) {
        streamUrl = await Get.find<YouTubeApi>().getStreamUrl(activeSong.sourceId.isNotEmpty ? activeSong.sourceId : activeSong.id);
      } else {
        streamUrl = await Get.find<SaavnApi>().getStreamUrl(activeSong.sourceId.isNotEmpty ? activeSong.sourceId : activeSong.id);
      }

      final mediaItem = MediaItem(
        id: activeSong.id,
        title: activeSong.title,
        artist: activeSong.artist,
        album: activeSong.album,
        duration: Duration(milliseconds: activeSong.durationMs),
        artUri: _getHighResArtUri(activeSong),
      );

      final isVideoMode = Get.isRegistered<SettingsController>() && Get.find<SettingsController>().videoModeEnabled.value;
      if (isVideoMode && activeSong.source == MusicSource.youtube) {
        await _audioHandler.setMediaItemOnly(mediaItem, streamUrl);
        debugPrint('AudioPlayerController: Primary source loaded (Video Mode, playback deferred until video loads)');
      } else {
        await _audioHandler.setMediaItemAndPlay(mediaItem, streamUrl);
        debugPrint('AudioPlayerController: Primary source loaded and playing successfully!');
      }
      success = true;
    } catch (e) {
      debugPrint('AudioPlayerController: Primary source failed: $e. Initiating fallback search...');
    }
    }

    if (!success) {
      try {
        if (song.source == MusicSource.youtube) {

          debugPrint('AudioPlayerController: Searching JioSaavn fallback for: ${song.title} ${song.artist}');
          final fallbackList = await Get.find<SaavnApi>().searchSongs('${song.title} ${song.artist}');

          SongModel? matchedSong;
          for (final candidate in fallbackList) {
            if (AudioPlayerController.isSongMatch(song, candidate)) {
              matchedSong = candidate;
              break;
            }
          }

          if (matchedSong != null) {
            activeSong = matchedSong;
            currentSong.value = matchedSong;

            streamUrl = await Get.find<SaavnApi>().getStreamUrl(matchedSong.id);

            final mediaItem = MediaItem(
              id: matchedSong.id,
              title: matchedSong.title,
              artist: matchedSong.artist,
              album: matchedSong.album,
              duration: Duration(milliseconds: matchedSong.durationMs),
              artUri: _getHighResArtUri(matchedSong),
            );

            await _audioHandler.setMediaItemAndPlay(mediaItem, streamUrl);
            success = true;
            debugPrint('AudioPlayerController: JioSaavn fallback loaded and playing successfully!');
          } else {
            throw Exception('No precise JioSaavn fallback matches found.');
          }
        } else {

          debugPrint('AudioPlayerController: Searching YouTube fallback for: ${song.title} ${song.artist}');
          final fallbackList = await Get.find<YouTubeApi>().search('${song.title} ${song.artist}');

          SongModel? matchedSong;
          for (final candidate in fallbackList) {
            if (AudioPlayerController.isSongMatch(song, candidate)) {
              matchedSong = candidate;
              break;
            }
          }

          if (matchedSong != null) {
            activeSong = matchedSong;
            currentSong.value = matchedSong;

            streamUrl = await Get.find<YouTubeApi>().getStreamUrl(matchedSong.id);

            final mediaItem = MediaItem(
              id: matchedSong.id,
              title: matchedSong.title,
              artist: matchedSong.artist,
              album: matchedSong.album,
              duration: Duration(milliseconds: matchedSong.durationMs),
              artUri: _getHighResArtUri(matchedSong),
            );

            final isVideoMode = Get.isRegistered<SettingsController>() && Get.find<SettingsController>().videoModeEnabled.value;
            if (isVideoMode && activeSong.source == MusicSource.youtube) {
              await _audioHandler.setMediaItemOnly(mediaItem, streamUrl);
              debugPrint('AudioPlayerController: YouTube fallback loaded (Video Mode, playback deferred)');
            } else {
              await _audioHandler.setMediaItemAndPlay(mediaItem, streamUrl);
              debugPrint('AudioPlayerController: YouTube fallback loaded and playing successfully!');
            }
            success = true;
          } else {
            throw Exception('No precise YouTube fallback matches found.');
          }
        }
      } catch (fallbackError) {
        debugPrint('AudioPlayerController: Fallback source failed: $fallbackError');
        errorMessage.value = 'Failed to load audio: $fallbackError';
      }
    }

    if (success) {
      try {
        Get.find<LibraryController>().addToHistory(activeSong);
      } catch (e) {
        debugPrint('AudioPlayerController: Failed to add to history: $e');
      }
    }
  }

  void _onTrackCompleted() {
    switch (repeatMode.value) {
      case RiftWaveRepeatMode.one:
        seekTo(Duration.zero);
        _audioHandler.play();
        break;
      case RiftWaveRepeatMode.all:
      case RiftWaveRepeatMode.off:
        skipToNext();
        break;
    }
  }

  int? _getNextIndex() {
    if (shuffleMode.value) {
      if (_shufflePosition < _shuffledIndices.length - 1) {
        _shufflePosition++;
        return _shuffledIndices[_shufflePosition];
      } else if (repeatMode.value == RiftWaveRepeatMode.all) {
        _generateShuffledIndices();
        _shufflePosition = 0;
        return _shuffledIndices[_shufflePosition];
      }
      return null;
    }

    if (currentQueueIndex.value < queue.length - 1) {
      return currentQueueIndex.value + 1;
    } else if (repeatMode.value == RiftWaveRepeatMode.all) {
      return 0;
    }
    return null;
  }

  int? _getPreviousIndex() {
    if (shuffleMode.value) {
      if (_shufflePosition > 0) {
        _shufflePosition--;
        return _shuffledIndices[_shufflePosition];
      } else if (repeatMode.value == RiftWaveRepeatMode.all) {
        _shufflePosition = _shuffledIndices.length - 1;
        return _shuffledIndices[_shufflePosition];
      }
      return null;
    }

    if (currentQueueIndex.value > 0) {
      return currentQueueIndex.value - 1;
    } else if (repeatMode.value == RiftWaveRepeatMode.all) {
      return queue.length - 1;
    }
    return null;
  }

  void _generateShuffledIndices() {
    final indices = List<int>.generate(queue.length, (i) => i);
    indices.shuffle(Random());

    if (currentQueueIndex.value >= 0 &&
        currentQueueIndex.value < queue.length) {
      indices.remove(currentQueueIndex.value);
      indices.insert(0, currentQueueIndex.value);
    }

    _shuffledIndices = indices;
    _shufflePosition = 0;
  }

  void _resetShuffleIndices() {
    if (shuffleMode.value) {
      _generateShuffledIndices();
    }
  }

  void _clearState() {
    currentSong.value = null;
    hasSong.value = false;
    currentQueueIndex.value = -1;
    currentPosition.value = Duration.zero;
    totalDuration.value = Duration.zero;
    bufferedPosition.value = Duration.zero;
    _shuffledIndices = [];
    _shufflePosition = 0;
    errorMessage.value = '';
  }

  Future<void> setVolume(double val) async {
    volume.value = val.clamp(0.0, 1.0);
    await _audioHandler.setVolume(val.clamp(0.0, 1.0));
  }

  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepTimerRemaining.value = duration;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = sleepTimerRemaining.value;
      if (remaining == null || remaining.inSeconds <= 0) {
        cancelSleepTimer();
        _audioHandler.pause();
        return;
      }
      sleepTimerRemaining.value = remaining - const Duration(seconds: 1);
    });
  }

  void setSleepTimerEndOfTrack() {
    cancelSleepTimer();
    sleepTimerRemaining.value = const Duration(seconds: -1);
    _audioHandler.onPlaybackCompleted = () {
      _audioHandler.pause();
      sleepTimerRemaining.value = null;
      _audioHandler.onPlaybackCompleted = _onTrackCompleted;
    };
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerRemaining.value = null;
  }

  Future<void> _persistQueue() async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      final songsList = queue.map((s) => {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'album': s.album,
        'thumbnailUrl': s.thumbnailUrl,
        'audioUrl': s.audioUrl,
        'durationMs': s.durationMs,
        'source': s.source.name,
        'sourceId': s.sourceId,
        'isDownloaded': s.isDownloaded,
        'localPath': s.localPath,
      }).toList();

      await box.put('queue', songsList);
      await box.put('currentIndex', currentQueueIndex.value);
    } catch (e) {
      debugPrint('AudioPlayerController: Failed to persist queue — $e');
    }
  }

  Future<void> _restoreQueue() async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      final savedQueue = box.get('queue');
      final savedIndex = box.get('currentIndex', defaultValue: -1) as int;

      if (savedQueue != null && savedQueue is List) {
        final songs = savedQueue.map<SongModel>((map) {
          final m = Map<String, dynamic>.from(map as Map);
          return SongModel(
            id: m['id'] as String? ?? '',
            title: m['title'] as String? ?? '',
            artist: m['artist'] as String? ?? '',
            album: m['album'] as String? ?? '',
            thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
            audioUrl: m['audioUrl'] as String? ?? '',
            durationMs: m['durationMs'] as int? ?? 0,
            source: m['source'] == 'saavn' ? MusicSource.saavn : MusicSource.youtube,
            sourceId: m['sourceId'] as String? ?? '',
            isDownloaded: m['isDownloaded'] as bool? ?? false,
            localPath: m['localPath'] as String?,
          );
        }).toList();

        if (songs.isNotEmpty) {
          queue.assignAll(songs);
          final idx = savedIndex.clamp(0, songs.length - 1);
          currentQueueIndex.value = idx;
          currentSong.value = songs[idx];
          hasSong.value = true;
          totalDuration.value =
              Duration(milliseconds: songs[idx].durationMs);
        }
      }
    } catch (e) {
      debugPrint('AudioPlayerController: Failed to restore queue — $e');
    }
  }

  static bool isSongMatch(SongModel original, SongModel fallback) {
    String clean(String str) {
      String temp = str.toLowerCase();
      temp = temp.replaceAll(RegExp(r'\(.*?\)'), '');
      temp = temp.replaceAll(RegExp(r'\[.*?\]'), '');
      temp = temp.replaceAll('official video', '');
      temp = temp.replaceAll('official audio', '');
      temp = temp.replaceAll('lyrics', '');
      temp = temp.replaceAll('lyric video', '');
      temp = temp.replaceAll('full audio', '');
      temp = temp.replaceAll('full video', '');
      return temp.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final origTitle = clean(original.title);
    final fallTitle = clean(fallback.title);

    if (origTitle.isEmpty || fallTitle.isEmpty) return false;

    bool titleMatch = origTitle == fallTitle ||
        origTitle.contains(fallTitle) ||
        fallTitle.contains(origTitle);

    if (!titleMatch) {
      final origWords = origTitle.split(' ').where((w) => w.length > 2).toList();
      if (origWords.isNotEmpty) {
        int matchCount = 0;
        for (final word in origWords) {
          if (fallTitle.contains(word)) {
            matchCount++;
          }
        }
        if (matchCount / origWords.length >= 0.7) {
          titleMatch = true;
        }
      }
    }

    final origArtist = clean(original.artist);
    final fallArtist = clean(fallback.artist);

    bool artistMatch = origArtist == fallArtist ||
        origArtist.contains(fallArtist) ||
        fallArtist.contains(origArtist);

    if (!artistMatch) {
      final origArtistWords = origArtist.split(' ').where((w) => w.length > 2).toList();
      if (origArtistWords.isNotEmpty) {
        for (final word in origArtistWords) {
          if (fallArtist.contains(word)) {
            artistMatch = true;
            break;
          }
        }
      }
    }

    return titleMatch && artistMatch;
  }

  Future<void> _refreshUpNextSuggestions(SongModel song) async {
    try {
      if (!Get.isRegistered<RecommendationEngine>()) return;
      final engine = Get.find<RecommendationEngine>();
      final suggestions = await engine.getSimilarToNowPlaying(song);
      final existingIds = queue.map((s) => s.id).toSet();
            final filtered = suggestions.where((s) => !existingIds.contains(s.id)).toList();
      upNextSuggestions.assignAll(filtered);
      _resolveThumbnailsAsync(filtered).then((resolved) {
        for (final r in resolved) {
          final idx = upNextSuggestions.indexWhere((q) => q.id == r.id);
          if (idx != -1) upNextSuggestions[idx] = r;
        }
      });
      debugPrint('AudioPlayerController: Up next suggestions refreshed — ${filtered.length} tracks');
    } catch (e) {
      debugPrint('AudioPlayerController: Failed to refresh up next suggestions: $e');
    }
  }


  bool _isVariation(String originalClean, String candidateTitle, String candidateArtist) {
    final candClean = _getCleanedTitle(candidateTitle, candidateArtist).toLowerCase();
    final origClean = originalClean.toLowerCase();
    
    if (origClean.isEmpty || candClean.isEmpty) return false;
    if (candClean == origClean) return true;
    if (candClean.contains(origClean) || origClean.contains(candClean)) return true;
    
    final origWords = origClean.split(' ').where((w) => w.length > 2).toSet();
    final candWords = candClean.split(' ').where((w) => w.length > 2).toSet();
    if (origWords.isEmpty || candWords.isEmpty) return false;
    
    final overlap = origWords.intersection(candWords).length;
    
    if (overlap >= origWords.length * 0.5 || overlap >= candWords.length * 0.5) return true;
    
    return false;
  }


  Future<List<SongModel>> _resolveThumbnailsAsync(List<SongModel> songs) async {
    final saavn = Get.find<SaavnApi>();
    final futures = songs.map((s) async {
      if (s.thumbnailUrl.isEmpty || s.thumbnailUrl.contains('2a96cbd8b46e442fc41c2b86b821562f')) {
        try {
          final res = await saavn.searchSongs('${s.title} ${s.artist}');
          if (res.isNotEmpty) {
            return s.copyWith(thumbnailUrl: res.first.thumbnailUrl);
          }
        } catch (_) {}
      }
      return s;
    });
    return (await Future.wait(futures)).toList();
  }

  Future<void> _fetchAndAppendSimilar(SongModel song) async {
    try {
      final primaryArtist = _getPrimaryArtist(song.artist);
      final cleanedTitle = _getCleanedTitle(song.title, song.artist);
      final saavn = Get.find<SaavnApi>();
      final yt = Get.find<YouTubeApi>();

      List<SongModel> similar = [];

      try {
        final lastfm = Get.find<LastFmApi>();
        debugPrint('AudioPlayerController: Fetching similar songs for cleanedTitle="$cleanedTitle", artist="$primaryArtist"');
        final songs = await lastfm.getSimilarSongs(primaryArtist, cleanedTitle);
        similar = songs.map((s) => s.copyWith(source: song.source)).toList();
      } catch (e) {
        debugPrint('Autoplay Fallback 1 (Last.fm Similar) failed: $e');
      }

      if (song.source == MusicSource.youtube) {

        if (similar.isEmpty) {
          try {
            final query = '$cleanedTitle $primaryArtist radio';
            final ytResults = await yt.search(query);
            similar = ytResults.where((s) => !_isVariation(cleanedTitle, s.title, s.artist)).toList();
          } catch (e) {
            debugPrint('Autoplay Fallback 2 (YouTube Radio Search) failed: $e');
          }
        }

        if (similar.isEmpty) {
          try {
            final ytResults = await yt.search('$primaryArtist songs');
            similar = ytResults.where((s) => !_isVariation(cleanedTitle, s.title, s.artist)).toList();
          } catch (e) {
            debugPrint('Autoplay Fallback 3 (YouTube Artist Search) failed: $e');
          }
        }

        if (similar.isEmpty) {
          try {
            final query = '$cleanedTitle $primaryArtist radio';
            final searchResults = await saavn.searchSongs(query);
            similar = searchResults
                .where((s) => !_isVariation(cleanedTitle, s.title, s.artist))
                .map((s) => s.copyWith(source: MusicSource.youtube, sourceId: ''))
                .toList();
          } catch (e) {
            debugPrint('Autoplay Fallback 4 (Saavn Radio Backup) failed: $e');
          }
        }
      } else {

        if (similar.isEmpty) {
          try {
            final query = '$cleanedTitle $primaryArtist radio';
            final searchResults = await saavn.searchSongs(query);
            similar = searchResults.where((s) => !_isVariation(cleanedTitle, s.title, s.artist)).toList();
          } catch (e) {
            debugPrint('Autoplay Fallback 2 (Saavn Radio Search) failed: $e');
          }
        }

        if (similar.isEmpty) {
          try {
            final artistId = await saavn.searchArtist(primaryArtist);
            if (artistId != null) {
              final songs = await saavn.getArtistSongs(artistId);
              similar = songs.where((s) => !_isVariation(cleanedTitle, s.title, s.artist)).toList();
            }
          } catch (e) {
            debugPrint('Autoplay Fallback 3 (Saavn Artist Details) failed: $e');
          }
        }

        if (similar.isEmpty) {
          try {
            final query = '$cleanedTitle $primaryArtist radio';
            final ytResults = await yt.search(query);
            similar = ytResults
                .where((s) => !_isVariation(cleanedTitle, s.title, s.artist))
                .map((s) => s.copyWith(source: MusicSource.saavn, sourceId: ''))
                .toList();
          } catch (e) {
            debugPrint('Autoplay Fallback 4 (YouTube Radio Backup) failed: $e');
          }
        }
      }

      if (currentSong.value?.id == song.id && similar.isNotEmpty) {
        final currentQueue = List<SongModel>.from(queue);
        final existingIds = currentQueue.map((s) => s.id).toSet();
        final newSongs = similar.where((s) => !existingIds.contains(s.id)).take(15).toList();
        queue.addAll(newSongs);
        _persistQueue();
        
        _resolveThumbnailsAsync(newSongs).then((resolved) {
          for (final resolvedSong in resolved) {
            final idx = queue.indexWhere((q) => q.id == resolvedSong.id);
            if (idx != -1 && resolvedSong.thumbnailUrl.isNotEmpty) {
              queue[idx] = resolvedSong;
            }
          }
        });
      }
    } catch (e) {
      Get.log('Error fetching similar songs for autoplay: $e');
    }
  }

  String _getCleanedTitle(String title, String artist) {
    String cleaned = title.toLowerCase();

    if (cleaned.contains('|')) {
      cleaned = cleaned.split('|').first.trim();
    }
    
    if (cleaned.contains('-') && !cleaned.startsWith('-')) {
      final parts = cleaned.split('-');
      if (parts.length > 1 && parts[1].toLowerCase().contains(artist.toLowerCase().trim())) {
        cleaned = parts.first.trim();
      }
    }

    final cleanArtist = artist.toLowerCase().trim();
    if (cleanArtist.isNotEmpty && cleaned.startsWith(cleanArtist)) {
      cleaned = cleaned.substring(cleanArtist.length).trim();
      if (cleaned.startsWith('-') || cleaned.startsWith(':') || cleaned.startsWith('|')) {
        cleaned = cleaned.substring(1).trim();
      }
    }

    cleaned = cleaned.replaceAll(RegExp(r'\(.*?\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[.*?\]'), '');
    
    final removeWords = ['official video', 'official audio', 'official music video', 'lyrics', 'lyric video', 'full audio', 'full video', 'karaoke', 'cover', 'remix', 'mashup', 'slowed', 'reverb', 'unplugged', 'audio song'];
    for (final word in removeWords) {
      cleaned = cleaned.replaceAll(word, '');
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  String _getPrimaryArtist(String artist) {
    if (artist.isEmpty) return '';
    String cleaned = artist;

    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*VEVO$', caseSensitive: false), '');

    final dividers = [
      RegExp(r'\bfeat\.?\b', caseSensitive: false),
      RegExp(r'\bft\.?\b', caseSensitive: false),
      '&',
      ',',
      'and',
      'And'
    ];
    for (final divider in dividers) {
      final parts = cleaned.split(divider);
      if (parts.isNotEmpty) {
        cleaned = parts[0];
      }
    }
    return cleaned.trim();
  }
}
