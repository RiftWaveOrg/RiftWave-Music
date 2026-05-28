import 'package:get/get.dart';





class LibraryController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<dynamic> playlists = <dynamic>[].obs;
  final RxList<dynamic> likedSongs = <dynamic>[].obs;
  final RxList<dynamic> downloads = <dynamic>[].obs;

  final RxInt selectedTab = 0.obs;

  void changeTab(int index) {
    selectedTab.value = index;
  }
}
