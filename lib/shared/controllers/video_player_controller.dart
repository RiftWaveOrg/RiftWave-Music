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

  late final Player player;
  late final VideoController videoController;

  StreamSubscription? _songSubscription;
  StreamSubscription? _videoModeSubscription;

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
        _fallbackToAudioOnly();
      }
    });

    
    _songSubscription = audioController.currentSong.listen((song) {
      if (isVideoMode.value) {
        _checkAndLoadVideoForCurrentSong();
      }
    });
    
    
    player.stream.position.listen((pos) {
      if (isHandlingPlayback) {
        audioController.currentPosition.value = pos;
      }
    });
    player.stream.duration.listen((dur) {
      if (isHandlingPlayback) {
        audioController.totalDuration.value = dur;
      }
    });
    player.stream.playing.listen((playing) {
      if (isHandlingPlayback) {
        audioController.isPlaying.value = playing;
        if (playing) {
          audioController.isBuffering.value = false;
        }
      }
    });
    player.stream.buffering.listen((buffering) {
      if (isHandlingPlayback) {
        audioController.isBuffering.value = buffering;
      }
    });
    player.stream.completed.listen((completed) {
      if (isHandlingPlayback && completed) {
        audioController.skipToNext();
      }
    });
    
    
    player.stream.videoParams.listen((params) {
      if (params.w != null && params.h != null && params.h! > 0) {
        videoAspectRatio.value = params.w! / params.h!;
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    if (isHandlingPlayback) {
      _handoffToAudioOnly();
    }
    _songSubscription?.cancel();
    _videoModeSubscription?.cancel();
    player.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isHandlingPlayback) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      
      _handoffToAudioOnly();
    } else if (state == AppLifecycleState.resumed) {
      
      _handoffToVideo();
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

    isVideoLoading.value = true;

    try {
      final manifest = await ytApi.getDualStreamManifest(song.id, settings.videoQuality.value);
      if (manifest != null) {
        final videoUrl = manifest['videoUrl']!;
        final audioUrl = manifest['audioUrl']!;

        
        isVideoAvailable.value = true;
        
        
        await audioController.pause(forceInternal: true);

        
        final media = Media(videoUrl);
        await player.open(media);
        await player.setAudioTrack(AudioTrack.uri(audioUrl));
        
        
        player.play();
        
        
        if (audioController.currentPosition.value.inSeconds > 0) {
          await player.seek(audioController.currentPosition.value);
        }
        
      } else {
        _fallbackToAudioOnly(showToast: true);
      }
    } catch (e) {
      print('Video Extraction Error: $e');
      _fallbackToAudioOnly(showToast: true);
    } finally {
      if (isVideoAvailable.value && !audioController.isPlaying.value) {
        audioController.isBuffering.value = true;
      }
      isVideoLoading.value = false;
    }
  }

  void _fallbackToAudioOnly({bool showToast = false}) {
    isVideoAvailable.value = false;
    if (showToast && isVideoMode.value) {
      Get.snackbar(
        'Music Video Unavailable',
        'Playing audio only.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    
    
    if (player.state.playing) {
      player.pause();
      audioController.seekTo(player.state.position);
      audioController.play(forceInternal: true);
    }
  }

  void _handoffToAudioOnly() {
    
    final pos = player.state.position;
    final playing = player.state.playing;
    
    player.pause();
    
    
    audioController.seekTo(pos);
    if (playing) {
      audioController.play(forceInternal: true);
    }
  }

  void _handoffToVideo() async {
    
    final pos = audioController.currentPosition.value;
    final playing = audioController.isPlaying.value;
    
    await audioController.pause(forceInternal: true);
    
    
    await player.seek(pos);
    if (playing) {
      player.play();
    }
  }

  
  Future<void> play() async => await player.play();
  Future<void> pause() async => await player.pause();
  Future<void> seek(Duration position) async => await player.seek(position);
  
  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
  }
}
