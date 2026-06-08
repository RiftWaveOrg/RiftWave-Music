import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';

class HomeController extends GetxController {
  final RxString currentMood = 'All'.obs;

  final RxList<SongModel> trendingSongs = <SongModel>[].obs;
  final RxList<SongModel> recentlyPlayed = <SongModel>[].obs;
  final RxList<Map<String, dynamic>> popularPlaylists = <Map<String, dynamic>>[].obs;
  final RxList<SongModel> quickPicks = <SongModel>[].obs;
  final RxList<SongModel> recommendedVideos = <SongModel>[].obs;
  final RxList<SongModel> forgottenFavorites = <SongModel>[].obs;
  final RxList<SongModel> similarToArtistSongs = <SongModel>[].obs;
  final RxList<SongModel> mixedForYou = <SongModel>[].obs;
  final RxList<SongModel> mashupSongs = <SongModel>[].obs;
  final RxString similarArtistName = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isDiscoveryLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString greeting = ''.obs;

  static const String _cacheBoxName = 'home_cache_box';
  late Box _cacheBox;

  @override
  void onInit() {
    super.onInit();
    _updateGreeting();
    _initAndLoadCache();

    ever<String>(
      Get.find<SettingsController>().regionCode,
      (_) => refreshData(),
    );
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Good Morning 🌅';
    } else if (hour < 17) {
      greeting.value = 'Good Afternoon ☀️';
    } else {
      greeting.value = 'Good Evening 🌙';
    }
  }

  Future<void> _initAndLoadCache() async {
    try {
      if (!Hive.isBoxOpen(_cacheBoxName)) {
        _cacheBox = await Hive.openBox(_cacheBoxName);
      } else {
        _cacheBox = Hive.box(_cacheBoxName);
      }
      _loadLocalHistory();

      if (quickPicks.isEmpty && trendingSongs.isEmpty) {
        isLoading.value = true;
      }

      refreshData();
    } catch (e) {
      debugPrint('HomeController: Cache load failed: ');
      isLoading.value = true;
      refreshData();
    }
  }

  void _loadLocalHistory() {
    try {
      final library = Get.find<LibraryController>();
      if (library.history.isNotEmpty) {
        recentlyPlayed.assignAll(library.history);
      }
    } catch (e) {
      debugPrint('HomeController: Failed to load local history: ');
    }
  }

  void changeMood(String mood) {
    if (currentMood.value == mood) return;
    currentMood.value = mood;
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    errorMessage.value = '';
    _updateGreeting();
    _loadLocalHistory();

    try {
      final ytApi = Get.find<YouTubeApi>();
      final region = Get.find<SettingsController>().currentRegion;
      final moodSuffix = currentMood.value == 'All' ? '' : '${currentMood.value} ';
      
      final trendingQuery = moodSuffix.isEmpty ? region.youtubeQuery : '${moodSuffix}trending music songs ${region.name}';
      final playlistQuery = moodSuffix.isEmpty ? 'popular music playlist ${region.name}' : '${moodSuffix}music playlist';
      final mixQuery = moodSuffix.isEmpty ? 'music song mix ${region.name}' : '${moodSuffix}song mix';
      final videoQuery = moodSuffix.isEmpty ? 'official music video hit song ${region.name}' : 'official music video song $moodSuffix';
      final hitsQuery = moodSuffix.isEmpty ? 'latest hit songs ${region.name}' : 'latest hit songs $moodSuffix';
      final mashupQuery = moodSuffix.isEmpty ? 'best music mashups ${region.name}' : '${moodSuffix}music mashups';

      final results = await Future.wait([
        ytApi.getTrending(trendingQuery).catchError((_) => <SongModel>[]),
        ytApi.getPopularPlaylists(playlistQuery).catchError((_) => <Map<String, dynamic>>[]),
        ytApi.search(mixQuery).catchError((_) => <SongModel>[]),
        ytApi.search(videoQuery).catchError((_) => <SongModel>[]),
        ytApi.search(hitsQuery).catchError((_) => <SongModel>[]),
        ytApi.search(mashupQuery).catchError((_) => <SongModel>[]),
      ]);

      final freshTrending = results[0] as List<SongModel>;
      final freshPlaylists = results[1] as List<Map<String, dynamic>>;
      final freshMix = results[2] as List<SongModel>;
      final freshVideos = results[3] as List<SongModel>;
      final freshHits = results[4] as List<SongModel>;
      final freshMashups = results[5] as List<SongModel>;

      trendingSongs.assignAll(freshTrending);
      popularPlaylists.assignAll(freshPlaylists);
      mixedForYou.assignAll(freshMix.isNotEmpty ? freshMix : freshHits);
      recommendedVideos.assignAll(freshVideos);
      mashupSongs.assignAll(freshMashups);

      // Synthesize Quick Picks (16 items)
      final List<SongModel> qpPool = [...freshHits, ...freshMix, ...recentlyPlayed];
      qpPool.shuffle();
      final uniqueQp = <String, SongModel>{};
      for (final s in qpPool) {
        if (!uniqueQp.containsKey(s.title)) uniqueQp[s.title] = s;
        if (uniqueQp.length >= 16) break;
      }
      quickPicks.assignAll(uniqueQp.values.toList());

      // Synthesize Forgotten Favorites
      if (recentlyPlayed.length > 5) {
        final older = recentlyPlayed.reversed.take(15).toList();
        older.shuffle();
        forgottenFavorites.assignAll(older);
      } else {
        forgottenFavorites.clear();
      }

      // Synthesize Similar to Artist
      if (recentlyPlayed.isNotEmpty) {
        final randomSongs = recentlyPlayed.toList()..shuffle();
        String chosenArtist = '';
        for (final s in randomSongs) {
          final a = s.artist.split(',').first.trim();
          if (a.isNotEmpty && a.toLowerCase() != 'unknown artist') {
            chosenArtist = a;
            break;
          }
        }
        if (chosenArtist.isNotEmpty) {
          similarArtistName.value = chosenArtist;
          final similar = await ytApi.search('similar to $chosenArtist $moodSuffix').catchError((_) => <SongModel>[]);
          similarToArtistSongs.assignAll(similar);
        } else {
          similarToArtistSongs.clear();
          similarArtistName.value = '';
        }
      } else {
        similarToArtistSongs.clear();
        similarArtistName.value = '';
      }

    } catch (e) {
      debugPrint('HomeController: Refresh failed: ');
      errorMessage.value = 'Failed to load content. Pull to retry.';
    } finally {
      isLoading.value = false;
      isDiscoveryLoading.value = false;
    }
  }
}
