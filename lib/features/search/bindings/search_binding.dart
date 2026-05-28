import 'package:get/get.dart';
import 'package:riftwave_music/features/search/controllers/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RiftSearchController>(() => RiftSearchController());
  }
}
