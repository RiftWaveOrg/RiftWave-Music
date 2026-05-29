import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';

enum SearchTab { youtube, saavn, all }
enum ResultTab { all, songs, artists, albums, playlists }

class MusicSearchController extends GetxController {
  final RxString query = ''.obs;
  final RxBool isSearching = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<SongModel> songResults = <SongModel>[].obs;
  final RxList<Map<String, dynamic>> artistResults = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> albumResults = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> playlistResults = <Map<String, dynamic>>[].obs;

  final RxList<String> recentSearches = <String>[].obs;

  final RxString activeFilter = 'YouTube'.obs;

  late final TextEditingController textController;
  Box? _recentBox;

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController();
    _initHive();

    debounce(query, _performSearch, time: const Duration(milliseconds: 300));
  }

  Future<void> _initHive() async {
    _recentBox = await Hive.openBox('recent_searches');
    final List<dynamic>? saved = _recentBox?.get('searches');
    if (saved != null) {
      recentSearches.assignAll(saved.cast<String>());
    }
  }

  void setActiveFilter(String filter) {
    activeFilter.value = filter;
  }

  void updateQuery(String value) {
    if (textController.text != value) {
      textController.text = value;
    }
    query.value = value;
  }

  void removeRecentSearch(String term) {
    recentSearches.remove(term);
    _recentBox?.put('searches', recentSearches.toList());
  }

  void clearRecentSearches() {
    recentSearches.clear();
    _recentBox?.put('searches', []);
  }

  Future<void> _performSearch(String value) async {
    if (value.trim().isEmpty) {
      songResults.clear();
      artistResults.clear();
      albumResults.clear();
      playlistResults.clear();
      isSearching.value = false;
      errorMessage.value = '';
      return;
    }

    if (!recentSearches.contains(value.trim())) {
      recentSearches.insert(0, value.trim());
      if (recentSearches.length > 10) recentSearches.removeLast();
      _recentBox?.put('searches', recentSearches.toList());
    }

    isSearching.value = true;
    errorMessage.value = '';

    try {
      final ytApi = Get.find<YouTubeApi>();
      final saavnApi = Get.find<SaavnApi>();

      final results = await Future.wait([
        saavnApi.searchSongs(value).catchError((_) => <SongModel>[]),
        ytApi.search(value).catchError((_) => <SongModel>[]),
        saavnApi.searchAllArtists(value).catchError((_) => <Map<String, dynamic>>[]),
        saavnApi.searchAlbums(value).catchError((_) => <Map<String, dynamic>>[]),
        saavnApi.searchPlaylists(value).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final saavnSongs = results[0] as List<SongModel>;
      final ytSongs = results[1] as List<SongModel>;
      final artists = results[2] as List<Map<String, dynamic>>;
      final albums = results[3] as List<Map<String, dynamic>>;
      final playlists = results[4] as List<Map<String, dynamic>>;

      
      final Map<String, SongModel> deduped = {};
      for (final s in [...saavnSongs, ...ytSongs]) {
        final key = '${s.title.toLowerCase().trim()}_${s.artist.toLowerCase().trim()}';
        if (!deduped.containsKey(key)) {
          deduped[key] = s;
        } else {
          
          if (s.source != MusicSource.youtube) {
            deduped[key] = s;
          }
        }
      }

      songResults.assignAll(deduped.values.toList());
      artistResults.assignAll(artists);
      albumResults.assignAll(albums);
      playlistResults.assignAll(playlists);

    } catch (e) {
      errorMessage.value = 'Failed to fetch results';
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    textController.clear();
    query.value = '';
    songResults.clear();
    artistResults.clear();
    albumResults.clear();
    playlistResults.clear();
    isSearching.value = false;
    errorMessage.value = '';
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
