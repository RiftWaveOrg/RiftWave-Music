import 'package:get/get.dart';
import 'package:riftwave_music/features/player/controllers/player_controller.dart';
import 'package:riftwave_music/features/player/controllers/dynamic_color_controller.dart';
import 'package:riftwave_music/shared/controllers/video_player_controller.dart';

class PlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerController>(() => PlayerController());
    Get.lazyPut<DynamicColorController>(() => DynamicColorController());
    Get.lazyPut<VideoPlayerController>(() => VideoPlayerController());
  }
}
