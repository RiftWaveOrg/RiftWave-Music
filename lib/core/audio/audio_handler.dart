import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class RiftWaveAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<int?> _currentIndexSub;

  void Function()? onPlaybackCompleted;

  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  RiftWaveAudioHandler() {

    _playerStateSub = _player.playerStateStream.listen(_broadcastPlaybackState);

    _durationSub = _player.durationStream.listen((duration) {
      final currentItem = mediaItem.valueOrNull;
      if (currentItem != null && duration != null) {

        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });

    _currentIndexSub = _player.currentIndexStream.listen((_) {});
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        onPlaybackCompleted?.call();
      }
    });
  }

  Future<void> setMediaItemAndPlay(MediaItem item, String audioUrl) async {

    mediaItem.add(item);

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await _player.play();
    } catch (e) {
      debugPrint('RiftWaveAudioHandler: Failed to load audio — $e');
    }
  }

  @override
  Future<void> prepareFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    try {
      await _player.setAudioSource(AudioSource.uri(uri));
    } catch (e) {
      debugPrint('RiftWaveAudioHandler: Failed to prepare audio — $e');
    }
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
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {

  }

  @override
  Future<void> skipToPrevious() async {

  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
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
      MediaControl.stop,
    ];

    playbackState.add(PlaybackState(
      controls: controls,

      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: audioProcessingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  Future<void> dispose() async {
    await _playerStateSub.cancel();
    await _durationSub.cancel();
    await _currentIndexSub.cancel();
    await _player.dispose();
  }
}
