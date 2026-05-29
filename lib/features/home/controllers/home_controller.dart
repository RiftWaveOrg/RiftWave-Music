import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/services/recommendation_engine.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';

class HomeController extends GetxController {
  final RxList<SongModel> trendingSongs = <SongModel>[].obs;
  final RxList<SongModel> recentlyPlayed = <SongModel>[].obs;
  final RxList<Map<String, dynamic>> newReleases = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> popularPlaylists = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> youtubePlaylists = <Map<String, dynamic>>[].obs;
  final RxList<SongModel> youtubeTrending = <SongModel>[].obs;

  final RxList<SongModel> dailyMix = <SongModel>[].obs;
  final RxList<SongModel> regionalCharts = <SongModel>[].obs;
  final RxList<Map<String, dynamic>> regionalArtists = <Map<String, dynamic>>[].obs;

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
      (_) => _refreshDiscoverySections(),
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

      final cachedTrending = _cacheBox.get('trending_songs');
      if (cachedTrending is List) {
        trendingSongs.assignAll(cachedTrending.cast<SongModel>());
      }

      final cachedReleases = _cacheBox.get('new_releases');
      if (cachedReleases is List) {
        newReleases.assignAll(cachedReleases.map((e) => Map<String, dynamic>.from(e)).toList());
      }

      final cachedPlaylists = _cacheBox.get('popular_playlists');
      if (cachedPlaylists is List) {
        popularPlaylists.assignAll(cachedPlaylists.map((e) => Map<String, dynamic>.from(e)).toList());
      }

      final cachedYtPlaylists = _cacheBox.get('youtube_playlists');
      if (cachedYtPlaylists is List) {
        youtubePlaylists.assignAll(cachedYtPlaylists.map((e) => Map<String, dynamic>.from(e)).toList());
      }

      final cachedYtTrending = _cacheBox.get('youtube_trending');
      if (cachedYtTrending is List) {
        youtubeTrending.assignAll(cachedYtTrending.cast<SongModel>());
      }

      _loadLocalHistory();

      if (trendingSongs.isEmpty && newReleases.isEmpty && popularPlaylists.isEmpty && youtubePlaylists.isEmpty) {
        isLoading.value = true;
      }

      refreshData();
    } catch (e) {
      debugPrint('HomeController: Cache load failed: $e');
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
      debugPrint('HomeController: Failed to load local history: $e');
    }
  }

  Future<void> refreshData() async {
    errorMessage.value = '';
    _updateGreeting();
    _loadLocalHistory();

    try {
      final saavn = Get.find<SaavnApi>();
      final ytApi = Get.find<YouTubeApi>();
      final region = Get.find<SettingsController>().currentRegion;

      final results = await Future.wait([
        saavn.getCharts().catchError((e) {
          debugPrint('HomeController: Failed to fetch charts: $e');
          return <SongModel>[];
        }),
        saavn.getNewReleases(language: region.saavnLanguage).catchError((e) {
          debugPrint('HomeController: Failed to fetch new releases: $e');
          return <Map<String, dynamic>>[];
        }),
        saavn.getPopularPlaylists(language: region.saavnLanguage).catchError((e) {
          debugPrint('HomeController: Failed to fetch popular playlists: $e');
          return <Map<String, dynamic>>[];
        }),
        ytApi.getPopularPlaylists('${region.youtubeQuery} playlist').catchError((e) {
          debugPrint('HomeController: Failed to fetch YouTube playlists: $e');
          return <Map<String, dynamic>>[];
        }),
        ytApi.getTrending(region.youtubeQuery).catchError((e) {
          debugPrint('HomeController: Failed to fetch YouTube trending: $e');
          return <SongModel>[];
        }),
      ]);

      final freshTrending = results[0] as List<SongModel>;
      final freshReleases = results[1] as List<Map<String, dynamic>>;
      final freshPlaylists = results[2] as List<Map<String, dynamic>>;
      final freshYtPlaylists = results[3] as List<Map<String, dynamic>>;
      final freshYtTrending = results[4] as List<SongModel>;

      if (freshTrending.isNotEmpty) {
        trendingSongs.assignAll(freshTrending);
        await _cacheBox.put('trending_songs', freshTrending);
      }

      if (freshReleases.isNotEmpty) {
        newReleases.assignAll(freshReleases);
        await _cacheBox.put('new_releases', freshReleases);
      }

      if (freshPlaylists.isNotEmpty) {
        popularPlaylists.assignAll(freshPlaylists);
        await _cacheBox.put('popular_playlists', freshPlaylists);
      }

      if (freshYtPlaylists.isNotEmpty) {
        youtubePlaylists.assignAll(freshYtPlaylists);
        await _cacheBox.put('youtube_playlists', freshYtPlaylists);
      }

      if (freshYtTrending.isNotEmpty) {
        youtubeTrending.assignAll(freshYtTrending);
        await _cacheBox.put('youtube_trending', freshYtTrending);
      }
    } catch (e) {
      debugPrint('HomeController: Parallel refresh failed: $e');
      if (trendingSongs.isEmpty && newReleases.isEmpty) {
        errorMessage.value = 'Failed to load content. Pull to retry.';
      }
    } finally {
      isLoading.value = false;
    }

    _refreshDiscoverySections();
  }

  Future<void> _refreshDiscoverySections() async {
    isDiscoveryLoading.value = true;
    try {
      final engine = Get.find<RecommendationEngine>();
      final settings = Get.find<SettingsController>();
      final region = settings.currentRegion;
      _loadLocalHistory();
      final history = List<SongModel>.from(recentlyPlayed);

      final results = await Future.wait([
        engine.getDailyMix(region: region, history: history).catchError((e) {
          debugPrint('HomeController: Daily mix failed: $e');
          return <SongModel>[];
        }),
        engine.getRegionalCharts(region).catchError((e) {
          debugPrint('HomeController: Regional charts failed: $e');
          return <SongModel>[];
        }),
        engine.getRegionalArtists(region).catchError((e) {
          debugPrint('HomeController: Regional artists failed: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      final freshDailyMix = results[0] as List<SongModel>;
      final freshRegionalCharts = results[1] as List<SongModel>;
      final freshRegionalArtists = results[2] as List<Map<String, dynamic>>;

      if (freshDailyMix.isNotEmpty) dailyMix.assignAll(freshDailyMix);
      if (freshRegionalCharts.isNotEmpty) regionalCharts.assignAll(freshRegionalCharts);
      if (freshRegionalArtists.isNotEmpty) regionalArtists.assignAll(freshRegionalArtists);
    } catch (e) {
      debugPrint('HomeController: Discovery refresh failed: $e');
    } finally {
      isDiscoveryLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecommendedArtists() async {
    try {
      final historySongs = recentlyPlayed;
      if (historySongs.isEmpty) {
        return await _getPopularArtistsFallback();
      }

      final Map<String, int> artistCounts = {};
      for (final song in historySongs) {
        final artist = song.artist;
        final mainArtist = artist.split(',').first.trim();
        if (mainArtist.toLowerCase() != 'unknown artist') {
          artistCounts[mainArtist] = (artistCounts[mainArtist] ?? 0) + 1;
        }
      }

      if (artistCounts.isEmpty) {
        return await _getPopularArtistsFallback();
      }

      final sortedArtists = artistCounts.keys.toList()
        ..sort((a, b) => artistCounts[b]!.compareTo(artistCounts[a]!));

      final topArtists = sortedArtists.take(3).toList();
      final saavn = Get.find<SaavnApi>();

      final futures = topArtists.map((name) async {
        try {
          final artistId = await saavn.searchArtist(name);
          if (artistId != null) {
            final details = await saavn.getArtistDetails(artistId);
            return {
              'id': artistId,
              'name': details['name'] as String? ?? name,
              'imageUrl': details['imageUrl'] as String? ?? '',
            };
          }
        } catch (e) {
          debugPrint('HomeController: Failed to fetch headshot for artist $name: $e');
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);
      final resolved = results.whereType<Map<String, dynamic>>().toList();

      if (resolved.isEmpty) {
        return await _getPopularArtistsFallback();
      }
      return resolved;
    } catch (e) {
      debugPrint('HomeController: Recommended artists exception: $e');
      return await _getPopularArtistsFallback();
    }
  }

  Future<List<Map<String, dynamic>>> _getPopularArtistsFallback() async {
    return [
      {
        'id': '459320',
        'name': 'Arijit Singh',
        'imageUrl': 'https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_150x150.jpg',
      },
      {
        'id': '456323',
        'name': 'Pritam',
        'imageUrl': 'https://c.saavncdn.com/artists/Pritam_Chakraborty-20170711073326_150x150.jpg',
      },
      {
        'id': '455663',
        'name': 'Anirudh Ravichander',
        'imageUrl': 'https://c.saavncdn.com/artists/Anirudh_Ravichander_003_20260121134149_150x150.jpg',
      },
      {
        'id': '456863',
        'name': 'Badshah',
        'imageUrl': 'https://c.saavncdn.com/artists/Badshah_006_20241118064015_150x150.jpg',
      },
      {
        'id': '464932',
        'name': 'Neha Kakkar',
        'imageUrl': 'https://c.saavncdn.com/artists/Neha_Kakkar_007_20241212115832_150x150.jpg',
      },
      {
        'id': '468245',
        'name': 'Diljit Dosanjh',
        'imageUrl': 'https://c.saavncdn.com/artists/Diljit_Dosanjh_005_20231025073054_150x150.jpg',
      },
      {
        'id': '455130',
        'name': 'Shreya Ghoshal',
        'imageUrl': 'https://c.saavncdn.com/artists/Shreya_Ghoshal_007_20241101074144_150x150.jpg',
      },
      {
        'id': '456269',
        'name': 'A.R. Rahman',
        'imageUrl': 'https://c.saavncdn.com/artists/AR_Rahman_002_20210120084455_150x150.jpg',
      },
    ];
  }
}
