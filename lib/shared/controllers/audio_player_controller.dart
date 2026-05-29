import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

import 'package:riftwave_music/core/audio/audio_handler.dart';
import 'package:riftwave_music/core/audio/repeat_mode.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

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

  List<int> _shuffledIndices = [];

  int _shufflePosition = 0;

  final List<StreamSubscription> _subscriptions = [];

  static const String _queueBoxName = 'queue_box';

  @override
  void onInit() {
    super.onInit();
    _audioHandler = Get.find<RiftWaveAudioHandler>();
    _audioHandler.onPlaybackCompleted = _onTrackCompleted;
    _listenToStreams();
    _restoreQueue();
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
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
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
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
    currentSong.value = song;
    hasSong.value = true;

    currentPosition.value = Duration.zero;
    totalDuration.value = Duration(milliseconds: song.durationMs);

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.durationMs),
      artUri: song.thumbnailUrl.isNotEmpty ? Uri.parse(song.thumbnailUrl) : null,
    );

    if (song.audioUrl.isNotEmpty) {
      await _audioHandler.setMediaItemAndPlay(mediaItem, song.audioUrl);
    } else {
      debugPrint('AudioPlayerController: Song has no audio URL — ${song.title}');
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
        'source': s.source,
        'sourceId': s.sourceId,
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
            source: m['source'] as String? ?? 'youtube',
            sourceId: m['sourceId'] as String? ?? '',
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
}
