import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

class VideoPlayerController extends GetxController with WidgetsBindingObserver {
  final SettingsController settings = Get.find<SettingsController>();

  final RxBool isVideoMode = false.obs;
  final RxBool isFullscreen = false.obs;
  final RxDouble videoAspectRatio = (16 / 9).obs;
  final Rx<Duration> videoBufferedPosition = Duration.zero.obs;
  final RxBool isReadyForCurrent = false.obs;
  final RxBool isVideoAvailable = true.obs;
  RxBool get isVideoLoading => false.obs; // Removed reactive buffering block for UI

  AudioPlayerController get audioController => Get.find<AudioPlayerController>();

  late final Player player;
  late final VideoController videoController;

  Timer? _syncTimer;

  bool get isHandlingPlayback => isVideoMode.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    player = Player();
    videoController = VideoController(player);
    player.setVolume(0.0); // Always muted, audio handles sound

    isVideoMode.value = settings.videoModeEnabled.value;

    settings.videoModeEnabled.listen((enabled) {
      isVideoMode.value = enabled;
      // We no longer stop the player when video mode is disabled.
      // It continues playing silently in sync with audio.
    });

    player.stream.buffer.listen((bufferDuration) {
      videoBufferedPosition.value = bufferDuration;
    });

    player.stream.videoParams.listen((params) {
      if (params.w != null && params.h != null && params.h! > 0) {
        videoAspectRatio.value = params.w! / params.h!;
      }
    });

    player.stream.buffering.listen((isBuffering) {
      if (!isBuffering && player.state.playlist.medias.isNotEmpty) {
         isReadyForCurrent.value = true;
      }
    });

    startSyncTimer();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    player.dispose();
    super.onClose();
  }

  Future<void> loadPlaylist(List<String> videoUrls, {int initialIndex = 0}) async {
    isReadyForCurrent.value = false;
    final medias = videoUrls.map((url) => Media(url.isNotEmpty ? url : 'asset://assets/blank.mp4')).toList();
    if (medias.isEmpty) return;
    
    await player.open(Playlist(medias, index: initialIndex), play: false);
  }

  Future<void> appendToPlaylist(String videoUrl) async {
    try {
      await player.add(Media(videoUrl.isNotEmpty ? videoUrl : 'asset://assets/silence.mp3'));
    } catch (e) {
      debugPrint('VideoPlayerController: appendToPlaylist error: $e');
    }
  }

  Future<void> jumpToIndex(int index) async {
    try {
      if (index >= 0 && index < player.state.playlist.medias.length) {
         isReadyForCurrent.value = false;
         await player.jump(index);
      }
    } catch (e) {
      debugPrint('VideoPlayerController: jumpToIndex error: $e');
    }
  }

  void startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!Get.isRegistered<AudioPlayerController>()) return;
      final audioController = Get.find<AudioPlayerController>();
      
      if (!audioController.isPlaying.value) {
        if (player.state.playing) player.pause();
        return;
      }
      
      if (!player.state.playing && !player.state.buffering) {
        player.play();
      }

      final audioPos = audioController.currentPosition.value;
      final videoPos = player.state.position;
      final diff = (audioPos - videoPos).inMilliseconds.abs();

      if (diff > 2500 && !player.state.buffering) {
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
