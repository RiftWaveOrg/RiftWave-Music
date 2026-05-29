import 'dart:async';
import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';

enum SearchTab { youtube, saavn, all }

class RiftSearchController extends GetxController {
  final RxString query = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<SongModel> searchResults = <SongModel>[].obs;
  final Rx<SearchTab> activeTab = SearchTab.youtube.obs;

  void setActiveTab(SearchTab tab) {
    activeTab.value = tab;
  }

  Timer? _debounce;

  void search(String value) {
    query.value = value;
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (value.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final ytApi = Get.find<YouTubeApi>();
        final saavnApi = Get.find<SaavnApi>();

        final results = await Future.wait([
          saavnApi.searchSongs(value).catchError((_) => <SongModel>[]),
          ytApi.search(value).catchError((_) => <SongModel>[]),
        ]);

        final List<SongModel> combined = [];
        final saavnResults = results[0];
        final ytResults = results[1];

        combined.addAll(saavnResults);
        combined.addAll(ytResults);

        searchResults.assignAll(combined);
      } catch (e) {
        Get.log(e.toString());
      } finally {
        isSearching.value = false;
      }
    });
  }

  void clearSearch() {
    query.value = '';
    searchResults.clear();
    isSearching.value = false;
    activeTab.value = SearchTab.youtube;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
