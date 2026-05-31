import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/api/exceptions/api_exceptions.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:flutter/foundation.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';

class SaavnApi extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://savan-api.vercel.app',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final response = await _dio.get('/search/songs', queryParameters: {
        'query': query,
      });

      final data = response.data['data'];
      List<dynamic> results = [];
      if (data is List) {
        results = data;
      } else if (data is Map) {
        results = data['results'] ?? [];
      }

      return _parseSongList(results);
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('JioSaavn Search Error: ${e.toString()}');
    }
  }

  Future<String> getStreamUrl(String id) async {
    try {
      final response = await _dio.get('/songs', queryParameters: {
        'id': id,
      });

      final data = response.data['data'];
      List<dynamic> results = [];
      if (data is List) {
        results = data;
      } else if (data is Map) {
        results = data['results'] ?? [];
      }

      if (results.isEmpty) {
        throw SongUnavailableException('JioSaavn song details not found.');
      }

      final songData = results.first;
      final downloadUrlList = songData['downloadUrl'] as List<dynamic>?;

      if (downloadUrlList == null || downloadUrlList.isEmpty) {
        throw SongUnavailableException('No download links available for this song.');
      }

      String preferredQuality = '320kbps';
      try {
        final settings = Get.find<SettingsController>();
        if (settings.initialized) {
          preferredQuality = settings.audioQuality.value;
        }
      } catch (_) {}

      String? streamUrl;
      for (final dl in downloadUrlList) {
        if (dl['quality'] == preferredQuality) {
          streamUrl = dl['link'] as String?;
          break;
        }
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = downloadUrlList.last['link'] as String?;
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw SongUnavailableException('No streaming URL resolved for quality $preferredQuality');
      }

      return streamUrl;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw SongUnavailableException('Failed to retrieve JioSaavn audio stream: ${e.toString()}');
    }
  }

  Future<List<SongModel>> getCharts() async {
    return getChartsByLanguage('hindi,english');
  }

  Future<List<SongModel>> getChartsByLanguage(String language) async {
    try {
      final response = await _dio.get('/modules', queryParameters: {
        'language': language,
      });

      final data = response.data['data'];
      if (data == null) {
        return await searchSongs('$language top hits');
      }

      final trending = data['trending'];
      if (trending != null) {
        final songs = trending['songs'] as List<dynamic>?;
        if (songs != null && songs.isNotEmpty) {
          return _parseSongList(songs);
        }
      }

      final charts = data['charts'] as List<dynamic>?;
      if (charts != null && charts.isNotEmpty) {
        final firstChartId = charts.first['id'] as String?;
        if (firstChartId != null) {
          final playlistResponse = await _dio.get('/playlists', queryParameters: {
            'id': firstChartId,
          });
          final playlistData = playlistResponse.data['data'];
          if (playlistData != null) {
            final playlistSongs = playlistData['songs'] as List<dynamic>?;
            if (playlistSongs != null && playlistSongs.isNotEmpty) {
              return _parseSongList(playlistSongs);
            }
          }
        }
      }

      return await searchSongs('$language top hits');
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('JioSaavn Charts Error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    try {
      final response = await _dio.get('/artists', queryParameters: {
        'id': artistId,
      });

      final data = response.data['data'];
      if (data == null) {
        throw SongUnavailableException('Artist details not found.');
      }

      final songsList = data['songs'] as List<dynamic>? ?? [];
      final parsedSongs = _parseSongList(songsList);

      String biography = '';
      final bioData = data['bio'];
      if (bioData is List) {
        biography = bioData
            .map((e) => (e is Map) ? (e['text'] as String? ?? '') : '')
            .where((t) => t.isNotEmpty)
            .join('\n\n');
      } else if (bioData is String) {
        biography = bioData;
      }

      return {
        'id': data['id'] as String? ?? artistId,
        'name': data['name'] as String? ?? 'Unknown Artist',
        'imageUrl': _extractImage(data['image']),
        'biography': biography,
        'songs': parsedSongs,
      };
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('JioSaavn Artist Error: ${e.toString()}');
    }
  }


  Future<List<Map<String, dynamic>>> searchAllArtists(String query) async {
    try {
      final response = await _dio.get('/search/artists', queryParameters: {'query': query});
      final data = response.data['data'];
      final List<dynamic> results = (data != null && data is Map) ? (data['results'] ?? []) : [];
      return results.map((e) => {
        'id': e['id']?.toString() ?? '',
        'name': e['name']?.toString() ?? '',
        'imageUrl': _getHighestResImage(e['image']) ?? '',
        'type': 'artist',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchAlbums(String query) async {
    try {
      final response = await _dio.get('/search/albums', queryParameters: {'query': query});
      final data = response.data['data'];
      final List<dynamic> results = (data != null && data is Map) ? (data['results'] ?? []) : [];
      return results.map((e) => {
        'id': e['id']?.toString() ?? '',
        'name': e['name']?.toString() ?? e['title']?.toString() ?? '',
        'subtitle': e['description']?.toString() ?? e['subtitle']?.toString() ?? '',
        'imageUrl': _getHighestResImage(e['image']) ?? '',
        'type': 'album',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaylists(String query) async {
    try {
      final response = await _dio.get('/search/playlists', queryParameters: {'query': query});
      final data = response.data['data'];
      final List<dynamic> results = (data != null && data is Map) ? (data['results'] ?? []) : [];
      return results.map((e) => {
        'id': e['id']?.toString() ?? '',
        'title': e['title']?.toString() ?? e['name']?.toString() ?? '',
        'subtitle': e['subtitle']?.toString() ?? e['description']?.toString() ?? '',
        'imageUrl': _getHighestResImage(e['image']) ?? '',
        'type': 'playlist',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String? _getHighestResImage(dynamic imageList) {
    if (imageList is List && imageList.isNotEmpty) {
      if (imageList.last is Map && imageList.last['url'] != null) {
        return imageList.last['url'].toString();
      } else if (imageList.last is String) {
        return imageList.last.toString();
      }
    }
    if (imageList is String) return imageList;
    return null;
  }

  Future<String?> searchArtist(String name) async {
    try {
      final response = await _dio.get('/search/artists', queryParameters: {
        'query': name,
      });

      final data = response.data['data'];
      if (data == null) return null;

      final List<dynamic> results = data['results'] ?? [];
      if (results.isEmpty) return null;

      // Try to find an exact match to avoid showing the wrong artist's image
      for (final result in results) {
        final resultName = result['name'] ?? result['title'] ?? '';
        if (resultName.toString().trim().toLowerCase() == name.trim().toLowerCase()) {
          return result['id']?.toString();
        }
      }

      // If no exact match is found, return null so we can safely fall back to YouTube!
      return null;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('JioSaavn Artist Search Error: ${e.toString()}');
    }
  }

  Future<List<SongModel>> getArtistSongs(String artistId) async {
    try {
      final response = await _dio.get('/artists/$artistId/songs');

      final data = response.data['data'];
      if (data == null) return [];

      final List<dynamic> results = data['results'] ?? [];
      return _parseSongList(results);
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('JioSaavn Artist Songs Error: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getNewReleases({String language = 'hindi,english'}) async {
    try {
      final response = await _dio.get('/modules', queryParameters: {
        'language': language,
      });
      final data = response.data['data'];
      if (data != null) {
        final albums = data['albums'] as List<dynamic>?;
        if (albums != null && albums.isNotEmpty) {
          return albums.map((a) => {
            'id': a['id']?.toString() ?? '',
            'name': a['name']?.toString() ?? '',
            'artist': _extractArtists(a['primaryArtists'] ?? a['artists']),
            'thumbnailUrl': _extractImage(a['image']),
          }).toList();
        }
      }

      final searchResults = await searchSongs('New Releases');
      return searchResults.map((s) => {
        'id': s.id,
        'name': s.album.isNotEmpty ? s.album : s.title,
        'artist': s.artist,
        'thumbnailUrl': s.thumbnailUrl,
      }).toList();
    } catch (e) {
      debugPrint('SaavnApi: Failed to fetch new releases: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPopularPlaylists({String language = 'hindi,english'}) async {
    try {
      final response = await _dio.get('/modules', queryParameters: {
        'language': language,
      });
      final data = response.data['data'];
      if (data != null) {
        final playlists = data['playlists'] as List<dynamic>?;
        if (playlists != null && playlists.isNotEmpty) {
          return playlists.map((p) => {
            'id': p['id'] as String? ?? '',
            'title': p['title'] as String? ?? '',
            'subtitle': p['subtitle'] as String? ?? '',
            'thumbnailUrl': _extractImage(p['image']),
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('SaavnApi: Failed to fetch popular playlists: $e');
      return [];
    }
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    try {
      final response = await _dio.get('/playlists', queryParameters: {
        'id': playlistId,
      });
      final data = response.data['data'];
      if (data != null) {
        final playlistSongs = data['songs'] as List<dynamic>?;
        if (playlistSongs != null) {
          return _parseSongList(playlistSongs);
        }
      }
      return [];
    } catch (e) {
      debugPrint('SaavnApi: Failed to fetch playlist songs: $e');
      return [];
    }
  }

  List<SongModel> _parseSongList(List<dynamic> jsonList) {
    final List<SongModel> songs = [];
    for (final s in jsonList) {
      final String id = s['id'] as String? ?? '';
      if (id.isEmpty) continue;

      String albumName = '';
      final albumData = s['album'];
      if (albumData is Map) {
        albumName = albumData['name'] as String? ?? '';
      } else if (albumData is String) {
        albumName = albumData;
      }

      int duration = 0;
      final durVal = s['duration'];
      if (durVal is int) {
        duration = durVal * 1000;
      } else if (durVal is String) {
        duration = (int.tryParse(durVal) ?? 0) * 1000;
      }

      songs.add(SongModel(
        id: id,
        title: s['name']?.toString() ?? '',
        artist: _extractArtists(s['primaryArtists'] ?? s['artists']),
        album: albumName,
        thumbnailUrl: _extractImage(s['image']),
        audioUrl: '',
        durationMs: duration,
        source: MusicSource.saavn,
        sourceId: id,
      ));
    }
    return songs;
  }

  String _extractArtists(dynamic artistsData) {
    if (artistsData is String) return artistsData;
    if (artistsData is List) {
      final names = artistsData.map((e) {
        if (e is Map) return e['name']?.toString() ?? '';
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
      if (names.isNotEmpty) return names.join(', ');
    }
    return 'Unknown Artist';
  }

  String _extractImage(dynamic imageData) {
    if (imageData is List && imageData.isNotEmpty) {
      final last = imageData.last;
      if (last is Map) return last['link']?.toString() ?? last['url']?.toString() ?? '';
      return last.toString();
    } else if (imageData is String) {
      return imageData;
    }
    return '';
  }

  Never _handleDioError(DioException e) {
    if (e.error is SocketException ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw NoInternetException();
    }
    if (e.response?.statusCode == 429) {
      throw RateLimitException();
    }
    throw SongUnavailableException('JioSaavn service unavailable: ${e.message}');
  }
}
