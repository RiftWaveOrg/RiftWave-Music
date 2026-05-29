import 'package:get/get.dart';

class PlayerController extends GetxController {
  final RxBool isExpanded = false.obs;
  final RxBool showLyrics = false.obs;
  final RxDouble dragOffset = 0.0.obs;

  void toggleLyrics() {
    showLyrics.value = !showLyrics.value;
  }

  void expand() => isExpanded.value = true;
  void collapse() => isExpanded.value = false;
}
