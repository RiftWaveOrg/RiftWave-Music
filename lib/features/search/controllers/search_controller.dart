import 'package:get/get.dart';





class RiftSearchController extends GetxController {
  final RxString query = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<dynamic> searchResults = <dynamic>[].obs;

  void search(String value) {
    query.value = value;
    if (value.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    
  }

  void clearSearch() {
    query.value = '';
    searchResults.clear();
    isSearching.value = false;
  }
}
