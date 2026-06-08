import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class RiftWaveAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer(
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  );

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<MediaItem> _mediaItems = [];

  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<int?> _currentIndexSub;
  Timer? _positionTimer;

  void Function()? onPlaybackCompleted;
  void Function(int newIndex)? onIndexChanged;
  void Function()? onSkipToNextCallback;
  void Function()? onSkipToPreviousCallback;

  
  
  bool _isTransitioning = false;

  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  RiftWaveAudioHandler() {
    _player.setAudioSource(_playlist);

    _playerStateSub = _player.playerStateStream.listen((state) {
      _broadcastPlaybackState(state);
      _managePositionTimer(state.playing);
    });

    _durationSub = _player.durationStream.listen((duration) {
      final currentItem = mediaItem.valueOrNull;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });

    _currentIndexSub = _player.currentIndexStream.listen((index) {
      if (index != null && index < _mediaItems.length) {
        mediaItem.add(_mediaItems[index]);
        onIndexChanged?.call(index);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_isTransitioning && _mediaItems.isNotEmpty) {
        onPlaybackCompleted?.call();
      }
    });
  }

  void _managePositionTimer(bool isPlaying) {
    _positionTimer?.cancel();
    if (isPlaying) {
      _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _broadcastPlaybackState(_player.playerState);
      });
    }
  }

  Future<void> setMediaItemOnly(MediaItem item, String audioUrl, {Map<String, String>? headers}) async {
    _isTransitioning = true;
    
    _mediaItems.clear();
    _mediaItems.add(item);
    mediaItem.add(item);
    
    debugPrint('RiftWaveAudioHandler: Loading primary audio URL: $audioUrl');
    
    
    try {
      await _playlist.clear();
      final uri = Uri.parse(audioUrl);
      await _playlist.add(AudioSource.uri(uri, tag: item, headers: headers));
      
      
      await _player.seek(Duration.zero, index: 0);
    } catch (e) {
      debugPrint('RiftWaveAudioHandler: Interrupted during setMediaItemOnly ($e). This is expected if skipped rapidly.');
    }
    
    _isTransitioning = false;
  }

  Future<void> preloadNextItem(MediaItem item, String audioUrl, {Map<String, String>? headers}) async {
    
    if (_mediaItems.any((m) => m.id == item.id)) {
        return;
    }

    _mediaItems.add(item);
    debugPrint('RiftWaveAudioHandler: Preloading next audio URL: $audioUrl');
    
    final uri = Uri.parse(audioUrl);
    await _playlist.add(AudioSource.uri(uri, tag: item, headers: headers));
  }

  Future<void> setMediaItemAndPlay(MediaItem item, String audioUrl, {Map<String, String>? headers}) async {
    try {
      await setMediaItemOnly(item, audioUrl, headers: headers);
      await _player.play();
    } catch (e) {
      debugPrint('RiftWaveAudioHandler: Interrupted during play ($e)');
    }
  }

  @override
  Future<void> prepareFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    _isTransitioning = true;
    try {
      await _playlist.clear();
      await _playlist.add(AudioSource.uri(uri));
    } catch (e) {
      debugPrint('RiftWaveAudioHandler: Failed to prepare audio — $e');
    }
    _isTransitioning = false;
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _isTransitioning = true;
    _positionTimer?.cancel();
    try {
      await _player.stop();
      await super.stop();
    } catch (e) {
      debugPrint('RiftWaveAudioHandler: Interrupted during stop ($e)');
    }
    
    
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.length > 1 && _player.currentIndex != null && _player.currentIndex! < _playlist.length - 1) {
       
       await _player.seekToNext();
    } else {
       
       onSkipToNextCallback?.call();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      onSkipToPreviousCallback?.call();
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  void _broadcastPlaybackState(PlayerState playerState) {
    final isPlaying = playerState.playing;
    final processingState = playerState.processingState;

    final audioProcessingState = switch (processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: audioProcessingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex ?? 0,
    ));
  }

  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _playerStateSub.cancel();
    await _durationSub.cancel();
    await _currentIndexSub.cancel();
    await _player.dispose();
  }
}
