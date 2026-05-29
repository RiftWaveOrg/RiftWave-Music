import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString greeting = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Good Morning';
    } else if (hour < 17) {
      greeting.value = 'Good Afternoon';
    } else {
      greeting.value = 'Good Evening';
    }
  }
}
