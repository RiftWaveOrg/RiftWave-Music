import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/api/lastfm_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/models/region.dart';

class RecommendationEngine extends GetxService {
  static const String _cacheBox = 'recommendation_cache';

  static const Map<String, List<String>> _regionalArtistSeeds = {
    'IN': ['Arijit Singh', 'Pritam', 'A.R. Rahman', 'Badshah', 'Neha Kakkar'],
    'IN_TA': ['Anirudh Ravichander', 'Harris Jayaraj', 'Yuvan Shankar Raja', 'D. Imman', 'G.V. Prakash Kumar'],
    'IN_TE': ['S.S. Thaman', 'Devi Sri Prasad', 'Manisharma', 'Mickey J Meyer', 'Bheems Ceciroleo'],
    'IN_KN': ['V. Harikrishna', 'Arjun Janya', 'Rajesh Ramanath', 'Gurukiran', 'Pooja Gandhi'],
    'IN_ML': ['Vidyasagar', 'M. Jayachandran', 'Deepak Dev', 'Bijibal', 'Gopi Sunder'],
    'IN_PB': ['Diljit Dosanjh', 'AP Dhillon', 'Sidhu Moosewala', 'Hardy Sandhu', 'Ammy Virk'],
    'IN_BN': ['Rabindra Sangeet', 'Arijit Singh', 'Nachiketa Chakraborty', 'Shreya Ghoshal'],
    'US': ['Taylor Swift', 'Drake', 'Billie Eilish', 'The Weeknd', 'Ariana Grande'],
    'GB': ['Ed Sheeran', 'Adele', 'Harry Styles', 'Dua Lipa', 'Sam Smith'],
    'CA': ['Drake', 'The Weeknd', 'Justin Bieber', 'Celine Dion', 'Shawn Mendes'],
    'AU': ['Tones and I', 'Flume', 'Troye Sivan', 'Sia', 'Kylie Minogue'],
    'PK': ['Ali Zafar', 'Atif Aslam', 'Rahat Fateh Ali Khan', 'Naseebo Lal', 'Asim Azhar'],
    'BD': ['James', 'Habib Wahid', 'Tahsan', 'Shafin Ahmed', 'Mila Islam'],
    'LK': ['Bathiya and Santhush', 'Dinesh Gamage', 'Nadeeka Guruge'],
    'NP': ['Narayan Gopal', 'Aruna Lama', 'Bartika Eam Rai', 'Karma', 'Paul Shah'],
    'AE': ['Fairuz', 'Amr Diab', 'Nancy Ajram', 'Elissa', 'Wael Kfoury'],
    'SA': ['Rashed Al Majid', 'Mohammed Abdu', 'Majid Al Muhandis', 'Rotana'],
    'DE': ['Rammstein', 'Mark Forster', 'Clueso', 'Wincent Weiss', 'Bushido'],
    'FR': ['Stromae', 'Aya Nakamura', 'Jul', 'Angele', 'Christine and the Queens'],
    'ES': ['Bad Bunny', 'Rosalia', 'Maluma', 'J Balvin', 'Karol G'],
    'MX': ['Luis Miguel', 'Juan Gabriel', 'Alejandro Fernandez', 'Christian Nodal', 'Grupo Frontera'],
    'BR': ['Anitta', 'Mc Kevinho', 'Thiaguinho', 'Jorge Mateus', 'Marilia Mendonca'],
    'AR': ['Gustavo Cerati', 'Mercedes Sosa', 'Charly Garcia', 'Nicki Nicole', 'Paulo Londra'],
    'JP': ['King Gnu', 'Kenshi Yonezu', 'YOASOBI', 'Official Hige Dandism', 'Ado'],
    'KR': ['BTS', 'BLACKPINK', 'Aespa', 'NewJeans', 'IVE'],
    'NG': ['Burna Boy', 'Wizkid', 'Davido', 'Tiwa Savage', 'Fireboy DML'],
    'GH': ['Shatta Wale', 'Sarkodie', 'Stonebwoy', 'R2Bees', 'KiDi'],
    'ZA': ['Kabza De Small', 'Black Coffee', 'Focalistic', 'Nasty C', 'Sho Madjozi'],
    'TR': ['Tarkan', 'Sezen Aksu', 'Hadise', 'MFO', 'Ceza'],
    'ID': ['Raisa', 'Tulus', 'Rizky Febian', 'Lyodra', 'Tiara Andini'],
    'PH': ['Ben&Ben', 'SB19', 'BINI', 'December Avenue', 'Parokya ni Edgar'],
    'MY': ['Siti Nurhaliza', 'Yuna', 'Joe Flizzow', 'SonaOne', 'Altimet'],
    'SG': ['Nathan Hartono', 'Linying', 'M1LDL1FE', 'Charlie Lim'],
    'IT': ['Laura Pausini', 'Tiziano Ferro', 'Vasco Rossi', 'Jovanotti', 'Marco Mengoni'],
    'RU': ['Земфира', 'Cream Soda', 'Monetochka', 'Ёлка', 'Би-2'],
  };

  Future<List<SongModel>> getDailyMix({
    required MusicRegion region,
    required List<SongModel> history,
  }) async {
    final cacheKey = 'daily_mix_${region.code}_${_todayKey()}';
    try {
      final box = await _openBox();
      final cached = box.get(cacheKey);
    } catch (e) {
      debugPrint('RecommendationEngine: Cache read error: $e');
    }

    final results = <SongModel>[];

    if (history.isNotEmpty) {
      final historyBased = await _getHistoryBasedSuggestions(history, region);
      results.addAll(historyBased);
    }

    final regional = await getRegionalCharts(region);
    final existing = results.map((s) => s.id).toSet();
    for (final s in regional) {
      if (!existing.contains(s.id)) {
        results.add(s);
        existing.add(s.id);
      }
    }

    final mixed = _smartBlend(results, history);

    if (mixed.isNotEmpty) {
      try {
        final box = await _openBox();
        await box.put(cacheKey, _songsToCache(mixed));
      } catch (e) {
        debugPrint('RecommendationEngine: Cache write error: $e');
      }
    }

    return mixed;
  }

  Future<List<SongModel>> getRegionalCharts(MusicRegion region) async {
    final results = <SongModel>[];
    final saavn = Get.find<SaavnApi>();
    final yt = Get.find<YouTubeApi>();

    try {
      final saavnCharts = await saavn.getChartsByLanguage(region.saavnLanguage);
      results.addAll(saavnCharts.take(10));
    } catch (e) {
      debugPrint('RecommendationEngine: Saavn regional charts failed: $e');
    }

    if (results.length < 10) {
      try {
        final ytResults = await yt.search(region.youtubeQuery);
        final existing = results.map((s) => s.id).toSet();
        for (final s in ytResults) {
          if (!existing.contains(s.id)) {
            results.add(s);
          }
        }
      } catch (e) {
        debugPrint('RecommendationEngine: YouTube regional search failed: $e');
      }
    }

    return results.take(20).toList();
  }

  Future<List<Map<String, dynamic>>> getRegionalArtists(MusicRegion region) async {
    final seeds = _regionalArtistSeeds[region.code] ??
        _regionalArtistSeeds['IN']!;
    final saavn = Get.find<SaavnApi>();
    final results = <Map<String, dynamic>>[];

    final futures = seeds.take(6).map((name) async {
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
      } catch (_) {}
      return {'id': '', 'name': name, 'imageUrl': ''};
    }).toList();

    final resolved = await Future.wait(futures);
    results.addAll(resolved);

    return results;
  }


  bool _isVariation(String originalClean, String candidateTitle, String candidateArtist) {
    final candClean = _cleanTitle(candidateTitle, candidateArtist).toLowerCase();
    final origClean = originalClean.toLowerCase();
    
    if (origClean.isEmpty || candClean.isEmpty) return false;
    if (candClean.contains(origClean) || origClean.contains(candClean)) return true;
    
    final origWords = origClean.split(' ').where((w) => w.length > 2).toSet();
    final candWords = candClean.split(' ').where((w) => w.length > 2).toSet();
    if (origWords.isEmpty || candWords.isEmpty) return false;
    
    final overlap = origWords.intersection(candWords).length;
    if (overlap >= origWords.length * 0.7 || overlap >= candWords.length * 0.7) return true;
    
    return false;
  }

  Future<List<SongModel>> getSimilarToNowPlaying(SongModel song) async {
    final results = <SongModel>[];
    final cleanTitle = _cleanTitle(song.title, song.artist);
    final primaryArtist = _primaryArtist(song.artist);

    try {
      final lastfm = Get.find<LastFmApi>();
      final similar = await lastfm.getSimilarSongs(primaryArtist, cleanTitle);
      results.addAll(similar.map((s) => s.copyWith(source: song.source)));
    } catch (e) {
      debugPrint('RecommendationEngine: Last.fm similar failed: $e');
    }

    if (results.isEmpty) {
      try {
        final saavn = Get.find<SaavnApi>();
        final query = '$cleanTitle $primaryArtist radio';
        final saavnResults = await saavn.searchSongs(query);
        results.addAll(
          saavnResults.where((s) => !_isVariation(cleanTitle, s.title, s.artist)),
        );
      } catch (e) {
        debugPrint('RecommendationEngine: Saavn similar fallback failed: $e');
      }
    }

    if (results.isEmpty) {
      try {
        final yt = Get.find<YouTubeApi>();
        final query = '$cleanTitle $primaryArtist radio';
        final ytResults = await yt.search(query);
        results.addAll(
          ytResults.where((s) => !_isVariation(cleanTitle, s.title, s.artist)),
        );
      } catch (e) {
        debugPrint('RecommendationEngine: YouTube similar fallback failed: $e');
      }
    }

    return results.take(10).toList();
  }

  Future<List<SongModel>> _getHistoryBasedSuggestions(
    List<SongModel> history,
    MusicRegion region,
  ) async {
    final Map<String, int> artistCounts = {};
    for (final song in history) {
      final artist = _primaryArtist(song.artist);
      if (artist.isNotEmpty && artist.toLowerCase() != 'unknown artist') {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }
    }

    final topArtists = artistCounts.keys.toList()
      ..sort((a, b) => artistCounts[b]!.compareTo(artistCounts[a]!));

    final seedArtists = topArtists.take(3).toList();
    final results = <SongModel>[];
    final existingIds = <String>{};

    final saavn = Get.find<SaavnApi>();

    final futures = seedArtists.map((artist) async {
      try {
        final lastfm = Get.find<LastFmApi>();
        final recentSong = history.firstWhere(
          (s) => _primaryArtist(s.artist) == artist,
          orElse: () => history.first,
        );
        return await lastfm.getSimilarSongs(artist, _cleanTitle(recentSong.title, artist));
      } catch (_) {}
      try {
        final artistId = await saavn.searchArtist(artist);
        if (artistId != null) {
          return await saavn.getArtistSongs(artistId);
        }
      } catch (_) {}
      return <SongModel>[];
    }).toList();

    final resolved = await Future.wait(futures);
    for (final list in resolved) {
      for (final song in list) {
        if (!existingIds.contains(song.id)) {
          results.add(song);
          existingIds.add(song.id);
        }
      }
    }

    return results;
  }

  List<SongModel> _smartBlend(List<SongModel> all, List<SongModel> history) {
    final historyIds = history.map((s) => s.id).toSet();
    final filtered = all.where((s) => !historyIds.contains(s.id)).toList();
    filtered.shuffle();
    return filtered.take(25).toList();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  String _primaryArtist(String artist) {
    return artist.split(',').first.trim();
  }

  String _cleanTitle(String title, String artist) {
    String t = title.toLowerCase();
    t = t.replaceAll(RegExp(r'\(.*?\)'), '');
    t = t.replaceAll(RegExp(r'\[.*?\]'), '');
    t = t.replaceAll('official video', '');
    t = t.replaceAll('official audio', '');
    t = t.replaceAll('lyrics', '');
    t = t.replaceAll('full audio', '');
    t = t.replaceAll(artist.toLowerCase(), '');
    return t.trim();
  }

  List<SongModel> _songsFromCache(List cached) {
    return cached.map<SongModel>((m) {
      final map = Map<String, dynamic>.from(m as Map);
      return SongModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String? ?? '',
        album: map['album'] as String? ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
        audioUrl: map['audioUrl'] as String? ?? '',
        durationMs: map['durationMs'] as int? ?? 0,
        source: (map['source'] as String?) == 'saavn' ? MusicSource.saavn : MusicSource.youtube,
        sourceId: map['sourceId'] as String? ?? '',
      );
    }).toList();
  }

  List<Map<String, dynamic>> _songsToCache(List<SongModel> songs) {
    return songs.map((s) => {
      'id': s.id,
      'title': s.title,
      'artist': s.artist,
      'album': s.album,
      'thumbnailUrl': s.thumbnailUrl,
      'audioUrl': s.audioUrl,
      'durationMs': s.durationMs,
      'source': s.source.name,
      'sourceId': s.sourceId,
    }).toList();
  }

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_cacheBox)) return Hive.box(_cacheBox);
    return await Hive.openBox(_cacheBox);
  }
}
