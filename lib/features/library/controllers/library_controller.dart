import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class LibraryController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<dynamic> playlists = <dynamic>[].obs;
  final RxList<SongModel> likedSongs = <SongModel>[].obs;
  final RxList<dynamic> downloads = <dynamic>[].obs;

  final RxInt selectedTab = 0.obs;

  void changeTab(int index) {
    selectedTab.value = index;
  }

  bool isLiked(String songId) {
    return likedSongs.any((s) => s.id == songId);
  }

  void toggleLike(SongModel song) {
    final index = likedSongs.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      likedSongs.removeAt(index);
    } else {
      likedSongs.add(song);
    }
  }
}
