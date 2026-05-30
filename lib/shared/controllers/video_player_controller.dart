import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class VideoPlayerController extends GetxController with WidgetsBindingObserver {
  final AudioPlayerController audioController = Get.find<AudioPlayerController>();
  final SettingsController settings = Get.find<SettingsController>();
  final YouTubeApi ytApi = Get.find<YouTubeApi>();

  final RxBool isVideoMode = false.obs;
  final RxBool isVideoLoading = false.obs;
  final RxBool isVideoAvailable = false.obs;
  final RxBool isFullscreen = false.obs;
  final RxDouble videoAspectRatio = (16 / 9).obs;
  final Rx<Duration> videoBufferedPosition = Duration.zero.obs;

  late final Player player;
  late final VideoController videoController;

  StreamSubscription? _songSubscription;
  StreamSubscription? _videoModeSubscription;
  StreamSubscription? _bufferingSub;
  Timer? _syncTimer;
  
  String? _preloadedSongId;
  bool _wasAudioPausedForVideoBuffering = false;

  bool get isHandlingPlayback => isVideoMode.value && isVideoAvailable.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    player = Player();
    videoController = VideoController(player);

    isVideoMode.value = settings.videoModeEnabled.value;

    _videoModeSubscription = settings.videoModeEnabled.listen((enabled) {
      isVideoMode.value = enabled;
      if (enabled) {
        _checkAndLoadVideoForCurrentSong();
      } else {
        isVideoAvailable.value = false;
        _syncTimer?.cancel();
        player.stop();
      }
    });

    _songSubscription = audioController.currentSong.listen((song) {
      if (isVideoMode.value) {
        _checkAndLoadVideoForCurrentSong();
      }
    });
    
    // Sync video buffering to UI
    player.stream.buffer.listen((bufferDuration) {
      videoBufferedPosition.value = bufferDuration;
    });
    
    player.stream.videoParams.listen((params) {
      if (params.w != null && params.h != null && params.h! > 0) {
        videoAspectRatio.value = params.w! / params.h!;
      }
    });
    
    // Gapless preloading listener
    ever(audioController.currentSong, (song) {
      if (song != null && isHandlingPlayback) {
        final nextIndex = audioController.currentQueueIndex.value + 1;
        if (nextIndex < audioController.queue.length) {
          preloadNextVideo(audioController.queue[nextIndex].id);
        }
      }
    });

    // Master Sync Listeners
    ever(audioController.isPlaying, (playing) {
      if (isHandlingPlayback) {
        if (playing && !player.state.buffering) {
          player.play();
        } else if (!playing && !player.state.buffering) {
          player.pause();
        }
      }
    });

    _bufferingSub = player.stream.buffering.listen((isBuffering) {
      if (!isHandlingPlayback) return;
      if (isBuffering) {
        isVideoLoading.value = true;
        if (audioController.isPlaying.value) {
          audioController.pause();
          _wasAudioPausedForVideoBuffering = true;
          debugPrint('VideoPlayerController: Video buffering -> Pausing audio');
        }
      } else {
        isVideoLoading.value = false;
        if (_wasAudioPausedForVideoBuffering) {
          _wasAudioPausedForVideoBuffering = false;
          audioController.play(forceInternal: true);
          debugPrint('VideoPlayerController: Video ready -> Resuming audio');
        }
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _songSubscription?.cancel();
    _videoModeSubscription?.cancel();
    _bufferingSub?.cancel();
    _syncTimer?.cancel();
    player.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isHandlingPlayback) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Not strictly necessary since audio continues and video is just visual
    }
  }

  Future<void> preloadNextVideo(String id) async {
    if (!isVideoMode.value) return;
    if (player.state.playlist.medias.length > 1) return; // already preloaded
    try {
      final manifest = await ytApi.getDualStreamManifest(id, settings.videoQuality.value);
      if (manifest != null) {
        final videoUrl = manifest['videoUrl']!;
        await player.add(Media(videoUrl));
        _preloadedSongId = id;
        debugPrint('VideoPlayerController: Successfully preloaded next video () to media_kit Playlist');
      }
    } catch (e) {
      debugPrint('VideoPlayerController: Failed to preload next video: ');
    }
  }

  Future<void> _checkAndLoadVideoForCurrentSong() async {
    final song = audioController.currentSong.value;
    if (song == null) {
      isVideoAvailable.value = false;
      return;
    }

    if (song.source != MusicSource.youtube) {
      isVideoAvailable.value = false;
      return;
    }
    
    if (_preloadedSongId == song.id) {
      debugPrint('VideoPlayerController: Using preloaded video for gapless playback!');
      _preloadedSongId = null;
      
      // If media_kit hasn't naturally advanced yet, force it.
      if (player.state.playlist.index < player.state.playlist.medias.length - 1) {
        await player.next();
      }
      
      // Keep it available. If it needs to buffer the first frame, the global listener will handle it!
      isVideoAvailable.value = true;
      isVideoLoading.value = false;
      return;
    }

    // INSTANTLY clear old video state
    _syncTimer?.cancel();
    isVideoAvailable.value = false;
    isVideoLoading.value = false;
    await player.stop();
    isVideoLoading.value = true;

    try {
      final manifest = await ytApi.getDualStreamManifest(song.id, settings.videoQuality.value);
      if (manifest != null) {
        final videoUrl = manifest['videoUrl']!;
        final media = Media(videoUrl);

        // ALWAYS mute media_kit — just_audio handles ALL audio
        await player.setVolume(0.0);

        // Open video — it starts streaming/buffering immediately
        player.open(Playlist([media]), play: true);
        isVideoAvailable.value = true;
        _startSyncTimer();

        // Safety timeout: if video never finishes buffering within 15 seconds, clear the spinner
        Future.delayed(const Duration(seconds: 15), () {
          if (isVideoLoading.value) {
            isVideoLoading.value = false;
          }
        });
      } else {
        isVideoAvailable.value = false;
        isVideoLoading.value = false;
      }
    } catch (e) {
      debugPrint('Video Extraction Error: $e');
      isVideoAvailable.value = false;
      isVideoLoading.value = false;
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!isHandlingPlayback || !audioController.isPlaying.value) return;
      
      final audioPos = audioController.currentPosition.value;
      final videoPos = player.state.position;
      final diff = (audioPos - videoPos).inMilliseconds.abs();
      
      if (diff > 500) {
        debugPrint('VideoPlayerController: Drift detected ($diff ms). Correcting video...');
        player.seek(audioPos);
      }
    });
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
  }

  Future<void> play() async => await player.play();
  Future<void> pause() async => await player.pause();
  Future<void> seek(Duration position) async => await player.seek(position);
}
