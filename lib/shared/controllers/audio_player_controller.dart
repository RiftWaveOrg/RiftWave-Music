import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:riftwave_music/features/player/controllers/lyrics_controller.dart';

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

  List<int> _internalPlaylistIndices = [];
  bool _isManagingPreload = false;

  @override
  void onInit() {
    super.onInit();
    _audioHandler = Get.find<RiftWaveAudioHandler>();
    _audioHandler.onPlaybackCompleted = _onTrackCompleted;
    _audioHandler.onIndexChanged = _onAudioHandlerIndexChanged;
    _audioHandler.onSkipToNextCallback = () => skipToNext();
    _audioHandler.onSkipToPreviousCallback = () => skipToPrevious();
    _listenToStreams();
    _restoreQueue();
    _requestNotificationPermission();

    bool isFirstLoad = true;
    ever<SongModel?>(currentSong, (song) {
      if (song != null && song.thumbnailUrl.isNotEmpty && song.thumbnailUrl != _lastColorUrl) {
        _lastColorUrl = song.thumbnailUrl;
        if (Get.isRegistered<DynamicColorController>()) {
          Get.find<DynamicColorController>().extractFromImageUrl(song.thumbnailUrl);
        }
      }
      if (song != null && song.id != _lastSuggestionSongId) {
        _lastSuggestionSongId = song.id;
        if (isFirstLoad) {
          isFirstLoad = false;
        } else {
          _refreshUpNextSuggestions(song);
        }
      }
    });

    interval(currentPosition, (pos) async {
      final prefs = await SharedPreferences.getInstance();
      if (currentSong.value != null) {
        await prefs.setInt('last_position_', pos.inSeconds);
      }
    }, time: const Duration(seconds: 5));
  }

  void _onAudioHandlerIndexChanged(int newIndex) {
    if (newIndex >= 0 && newIndex < _internalPlaylistIndices.length) {
      final uiIndex = _internalPlaylistIndices[newIndex];
      if (uiIndex != currentQueueIndex.value) {
        currentQueueIndex.value = uiIndex;
        if (shuffleMode.value) {
          _shufflePosition = _shuffledIndices.indexOf(uiIndex);
        }
        currentSong.value = queue[uiIndex];
        totalDuration.value = Duration(milliseconds: queue[uiIndex].durationMs);
        _persistQueue();
        if (Get.isRegistered<VideoPlayerController>()) {
           Get.find<VideoPlayerController>().jumpToIndex(newIndex);
        }
        _managePreloadQueue();
      }
    }
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
          
          final shouldRequest = await Get.dialog<bool>(
            AlertDialog(
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
                  onPressed: () => Get.back(result: false),
                  child: Text('Not Now', style: TextStyle(color: colorScheme.onSurface.withAlpha(150))),
                ),
                FilledButton(
                  onPressed: () => Get.back(result: true),
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
        
        
        // Preloading is now managed proactively by _managePreloadQueue
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
    _persistQueue();
    await _loadAndPlay(song);
  }

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= queue.length) return;
    currentQueueIndex.value = index;

    if (shuffleMode.value) {
      _shufflePosition = _shuffledIndices.indexOf(index);
      if (_shufflePosition == -1) _shufflePosition = 0;
    }

    _persistQueue();
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

  bool wantsToPlayAfterLoad = false;

  Future<void> play({bool forceInternal = false}) async {
    if (_audioHandler.mediaItem.value == null && currentSong.value != null) {
      if (isBuffering.value) {
        wantsToPlayAfterLoad = true;
        return;
      }
      await _loadAndPlay(currentSong.value!);
      return;
    }
    await _audioHandler.play();
  }

  Future<void> pause({bool forceInternal = false}) async {
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
    _persistQueue();
    
    int internalIdx = _internalPlaylistIndices.indexOf(nextIndex);
    if (internalIdx != -1) {
       currentSong.value = queue[nextIndex];
       totalDuration.value = Duration(milliseconds: queue[nextIndex].durationMs);
       await _audioHandler.jumpToIndex(internalIdx);
       if (Get.isRegistered<VideoPlayerController>()) {
          await Get.find<VideoPlayerController>().jumpToIndex(internalIdx);
       }
       _managePreloadQueue(); // Fill up the buffer ahead
    } else {
       await _loadAndPlay(queue[nextIndex]);
    }
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
    _persistQueue();
    
    int internalIdx = _internalPlaylistIndices.indexOf(prevIndex);
    if (internalIdx != -1) {
       currentSong.value = queue[prevIndex];
       totalDuration.value = Duration(milliseconds: queue[prevIndex].durationMs);
       await _audioHandler.jumpToIndex(internalIdx);
       if (Get.isRegistered<VideoPlayerController>()) {
          await Get.find<VideoPlayerController>().jumpToIndex(internalIdx);
       }
       _managePreloadQueue();
    } else {
       await _loadAndPlay(queue[prevIndex]);
    }
  }

  Future<void> seekTo(Duration position) async {
    if (Get.isRegistered<VideoPlayerController>()) {
      final vpc = Get.find<VideoPlayerController>();
      if (vpc.isHandlingPlayback) {
        await vpc.seek(position);
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

  void playNext(SongModel song) {
    if (queue.isEmpty) {
      playSong(song);
      return;
    }
    queue.insert(currentQueueIndex.value + 1, song);
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
    try {
      await _audioHandler.stop();
    } catch (e) {
      debugPrint('AudioPlayerController: Error stopping audio handler: $e');
    }
    try {
      if (Get.isRegistered<VideoPlayerController>()) {
        await Get.find<VideoPlayerController>().player.stop();
      }
    } catch (e) {
      debugPrint('AudioPlayerController: Error stopping video player: $e');
    }
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

  
  int? _getNextIndexFor(int currentIndex) {
    if (shuffleMode.value) {
      int pos = _shuffledIndices.indexOf(currentIndex);
      if (pos != -1 && pos < _shuffledIndices.length - 1) {
        return _shuffledIndices[pos + 1];
      } else if (repeatMode.value == RiftWaveRepeatMode.all && _shuffledIndices.isNotEmpty) {
        return _shuffledIndices[0];
      }
      return null;
    }
    if (currentIndex < queue.length - 1) {
      return currentIndex + 1;
    } else if (repeatMode.value == RiftWaveRepeatMode.all && queue.isNotEmpty) {
      return 0;
    }
    return null;
  }

  List<int> _getUpcomingIndices(int startIndex, int count) {
    if (queue.isEmpty) return [];
    List<int> res = [startIndex];
    int current = startIndex;
    for (int i = 1; i < count; i++) {
      int? next = _getNextIndexFor(current);
      if (next == null || res.contains(next)) break;
      res.add(next);
      current = next;
    }
    return res;
  }

  
  Future<Map<String, dynamic>> _extractUrlsForIndex(int uiIdx) async {
    SongModel song = queue[uiIdx];

    if (song.sourceId.isEmpty) {
      try {
        if (song.source == MusicSource.youtube) {
          final searchResults = await Get.find<YouTubeApi>().search('${song.title} ${song.artist}');
          if (searchResults.isNotEmpty) {
            song = song.copyWith(sourceId: searchResults.first.sourceId, thumbnailUrl: searchResults.first.thumbnailUrl.isNotEmpty ? searchResults.first.thumbnailUrl : song.thumbnailUrl);
            queue[uiIdx] = song;
          }
        } else {
          final searchResults = await Get.find<SaavnApi>().searchSongs('${song.title} ${song.artist}');
          if (searchResults.isNotEmpty) {
            song = song.copyWith(sourceId: searchResults.first.sourceId, thumbnailUrl: searchResults.first.thumbnailUrl.isNotEmpty ? searchResults.first.thumbnailUrl : song.thumbnailUrl);
            queue[uiIdx] = song;
          }
        }
      } catch (e) {
        debugPrint('AudioPlayerController: Search resolution failed for ${song.title}');
      }
    }

    String aUrl = '';
    String vUrl = '';

    if (song.isDownloaded && song.localPath != null) {
      aUrl = Uri.file(song.localPath!).toString();
    }

    if (aUrl.isEmpty) {
      try {
        if (song.source == MusicSource.youtube) {
          final manifest = await Get.find<YouTubeApi>().getDualStreamManifest(
            song.sourceId.isNotEmpty ? song.sourceId : song.id,
            Get.isRegistered<SettingsController>() ? Get.find<SettingsController>().videoQuality.value : '720p',
          );
          if (manifest != null) {
            aUrl = manifest['audioUrl'] ?? '';
            vUrl = manifest['videoUrl'] ?? '';
          } else {
             aUrl = await Get.find<YouTubeApi>().getStreamUrl(song.sourceId.isNotEmpty ? song.sourceId : song.id);
          }
        } else {
          aUrl = await Get.find<SaavnApi>().getStreamUrl(song.sourceId.isNotEmpty ? song.sourceId : song.id);
        }
      } catch (e) {
        debugPrint('AudioPlayerController: Extraction failed for ${song.title}: $e');
      }
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.durationMs),
      artUri: _getHighResArtUri(song),
    );

    if (aUrl.isNotEmpty) {
      return {
        'mediaItem': mediaItem,
        'audioUrl': aUrl,
        'videoUrl': vUrl.isNotEmpty ? vUrl : aUrl,
      };
    } else {
      return {
        'mediaItem': mediaItem,
        'audioUrl': 'asset://assets/silence.mp3',
        'videoUrl': 'asset://assets/silence.mp3',
      };
    }
  }

  Future<void> _managePreloadQueue({bool forceReset = false, bool playWhenReady = false}) async {
    if (_isManagingPreload) return;
    _isManagingPreload = true;

    try {
      if (queue.isEmpty || currentQueueIndex.value < 0) {
        _isManagingPreload = false;
        return;
      }

      int currentInternalIndex = _internalPlaylistIndices.indexOf(currentQueueIndex.value);

      if (currentInternalIndex == -1 || forceReset) {
        
        final targetIndices = _getUpcomingIndices(currentQueueIndex.value, 4);
        final firstExtraction = await _extractUrlsForIndex(targetIndices[0]);
        
        _internalPlaylistIndices = [targetIndices[0]];
        
        await _audioHandler.updatePlaylist([firstExtraction['mediaItem']], [firstExtraction['audioUrl']], initialIndex: 0);
        if (Get.isRegistered<VideoPlayerController>()) {
           await Get.find<VideoPlayerController>().loadPlaylist([firstExtraction['videoUrl']], initialIndex: 0);
        }

        if (playWhenReady) {
          _waitForReadyAndPlay();
        }
        for (int i = 1; i < targetIndices.length; i++) {
          final extraction = await _extractUrlsForIndex(targetIndices[i]);
          _internalPlaylistIndices.add(targetIndices[i]);
          await _audioHandler.appendToPlaylist(extraction['mediaItem'], extraction['audioUrl']);
          if (Get.isRegistered<VideoPlayerController>()) {
             await Get.find<VideoPlayerController>().appendToPlaylist(extraction['videoUrl']);
          }
        }

      } else {
        int numAhead = _internalPlaylistIndices.length - currentInternalIndex;
        while (numAhead < 4) {
           int lastInternal = _internalPlaylistIndices.last;
           int? nextQueueIdx = _getNextIndexFor(lastInternal);
           if (nextQueueIdx == null || _internalPlaylistIndices.contains(nextQueueIdx)) break;
           final extraction = await _extractUrlsForIndex(nextQueueIdx);
           
           _internalPlaylistIndices.add(nextQueueIdx);
           await _audioHandler.appendToPlaylist(extraction['mediaItem'], extraction['audioUrl']);
           if (Get.isRegistered<VideoPlayerController>()) {
              await Get.find<VideoPlayerController>().appendToPlaylist(extraction['videoUrl']);
           }
           numAhead++;
        }
        
        if (playWhenReady) {
          await _waitForReadyAndPlay();
        }
      }

    } finally {
      _isManagingPreload = false;
    }
  }

  Future<void> _waitForReadyAndPlay() async {
     isBuffering.value = true;
     
     // Wait until audio is ready
     int attempts = 0;
     while (attempts < 20) { // 10 seconds max
        if (_audioHandler.player.playerState.processingState == ProcessingState.ready) {
           break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
     }

     if (Get.isRegistered<VideoPlayerController>()) {
        final vpc = Get.find<VideoPlayerController>();
        attempts = 0;
        while (attempts < 20) {
           if (vpc.isReadyForCurrent.value) {
              break;
           }
           await Future.delayed(const Duration(milliseconds: 500));
           attempts++;
        }
     }

     isBuffering.value = false;
     await _audioHandler.play();
  }

  Future<void> _loadAndPlay(SongModel song) async {
    errorMessage.value = '';
    currentSong.value = song;
    hasSong.value = true;
    wantsToPlayAfterLoad = false;
    
    try {
      await _audioHandler.pause();
    } catch (_) {}

    final remainingInQueue = queue.length - 1 - currentQueueIndex.value;
    if (remainingInQueue < 5) {
      _fetchAndAppendSimilar(song);
    }

    currentPosition.value = Duration.zero;
    totalDuration.value = Duration(milliseconds: song.durationMs);

    try {
      Get.find<LibraryController>().addToHistory(song);
    } catch (e) {}

    await _managePreloadQueue(forceReset: true, playWhenReady: true);
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

      if (song.source == MusicSource.youtube) {
        try {
          debugPrint('AudioPlayerController: Fetching YouTube related songs for ${song.title}');
          final ytResult = await yt.getRelatedSongs(song.sourceId.isNotEmpty ? song.sourceId : song.id);
          similar = ytResult;
        } catch (e) {
          debugPrint('Autoplay YouTube Related failed: $e');
        }
      }

      if (similar.isEmpty) {
        try {
          final lastfm = Get.find<LastFmApi>();
          debugPrint('AudioPlayerController: Fetching similar songs for cleanedTitle="$cleanedTitle", artist="$primaryArtist"');
          final songs = await lastfm.getSimilarSongs(primaryArtist, cleanedTitle);
          similar = songs.map((s) => s.copyWith(source: song.source)).toList();
        } catch (e) {
          debugPrint('Autoplay Fallback 1 (Last.fm Similar) failed: $e');
        }
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
