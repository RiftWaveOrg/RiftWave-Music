import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:riftwave_music/core/api/exceptions/api_exceptions.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class LastFmApi extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://ws.audioscrobbler.com/2.0/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Initialize to working fallback synchronously to prevent LateInitializationErrors.
  String _apiKey = 'b6096b3e21b6fe47b25cfe964c00502b';

  @override
  void onInit() {
    super.onInit();
    _initApiKey();
  }

  Future<void> _initApiKey() async {
    try {
      // 1. Try checking compile-time environment definitions (e.g. --dart-define-from-file=.env)
      const envKey = String.fromEnvironment('LASTFM_API_KEY');
      if (envKey.isNotEmpty) {
        _apiKey = envKey;
        return;
      }

      // 2. Try loading from packaged .env asset via rootBundle
      try {
        final content = await rootBundle.loadString('.env');
        final lines = content.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
          final parts = trimmed.split('=');
          if (parts[0].trim() == 'LASTFM_API_KEY') {
            _apiKey = parts.sublist(1).join('=').trim().replaceAll('"', '').replaceAll("'", "");
            return;
          }
        }
      } catch (_) {}

      // 3. Try loading from local File (useful for desktop targets and test environments)
      final file = File('.env');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
          final parts = trimmed.split('=');
          if (parts[0].trim() == 'LASTFM_API_KEY') {
            _apiKey = parts.sublist(1).join('=').trim().replaceAll('"', '').replaceAll("'", "");
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<List<SongModel>> getSimilarSongs(String artist, String title) async {
    try {
      final keyPreview = _apiKey.length > 8 
          ? '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}' 
          : _apiKey;
      debugPrint('LastFmApi.getSimilarSongs: querying artist="$artist", track="$title" with apiKey="$keyPreview"');
      final response = await _dio.get('', queryParameters: {
        'method': 'track.getsimilar',
        'artist': artist,
        'track': title,
        'api_key': _apiKey,
        'format': 'json',
        'limit': 10,
      });

      final data = response.data;
      if (data == null || data['similartracks'] == null) {
        debugPrint('LastFmApi.getSimilarSongs: null or missing similartracks object');
        return [];
      }

      final trackList = data['similartracks']['track'] as List<dynamic>? ?? [];
      final List<SongModel> songs = [];

      for (final t in trackList) {
        final String name = t['name'] as String? ?? '';
        final artistData = t['artist'];
        final String artistName = (artistData is Map) ? artistData['name'] as String? ?? '' : '';
        if (name.isEmpty || artistName.isEmpty) continue;

        String imgUrl = '';
        final imgList = t['image'] as List<dynamic>?;
        if (imgList != null && imgList.isNotEmpty) {
          imgUrl = imgList.last['#text'] as String? ?? '';
          if (imgUrl.contains('2a96cbd8b46e442fc41c2b86b821562f')) {
            imgUrl = '';
          }
        }

        final durVal = t['duration'];
        final duration = (durVal is int) ? durVal * 1000 : 0;

        songs.add(SongModel(
          id: 'lastfm_${name}_$artistName'.hashCode.toString(),
          title: name,
          artist: artistName,
          album: 'Last.fm Similar',
          thumbnailUrl: imgUrl,
          audioUrl: '',
          durationMs: duration,
          source: MusicSource.youtube,
          sourceId: '',
        ));
      }

      debugPrint('LastFmApi.getSimilarSongs: successfully retrieved ${songs.length} similar tracks');
      return songs;
    } on DioException catch (e) {
      debugPrint('LastFmApi.getSimilarSongs DioException: status=${e.response?.statusCode}, message=${e.message}, data=${e.response?.data}');
      _handleDioError(e);
    } catch (e) {
      debugPrint('LastFmApi.getSimilarSongs standard Exception: $e');
      if (e is ApiException) rethrow;
      throw ParseException('Last.fm Similar Songs Error: ${e.toString()}');
    }
  }

  Future<String> getArtistBio(String artist) async {
    try {
      final keyPreview = _apiKey.length > 8 
          ? '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}' 
          : _apiKey;
      debugPrint('LastFmApi.getArtistBio: querying artist="$artist" with apiKey="$keyPreview"');
      final response = await _dio.get('', queryParameters: {
        'method': 'artist.getinfo',
        'artist': artist,
        'api_key': _apiKey,
        'format': 'json',
      });

      final data = response.data;
      if (data == null || data['artist'] == null) {
        debugPrint('LastFmApi.getArtistBio: returned null or missing artist object');
        return '';
      }

      final bio = data['artist']['bio'];
      if (bio == null) {
        debugPrint('LastFmApi.getArtistBio: returned missing bio object');
        return '';
      }

      final String content = bio['content'] as String? ?? bio['summary'] as String? ?? '';
      debugPrint('LastFmApi.getArtistBio: successfully fetched bio, length=${content.length}');

      return content.replaceAll(RegExp(r'<[^>]*>|Read more on Last.fm.*'), '').trim();
    } on DioException catch (e) {
      debugPrint('LastFmApi.getArtistBio DioException: status=${e.response?.statusCode}, message=${e.message}, data=${e.response?.data}');
      _handleDioError(e);
    } catch (e) {
      debugPrint('LastFmApi.getArtistBio standard Exception: $e');
      if (e is ApiException) rethrow;
      throw ParseException('Last.fm Biography Error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getAlbumInfo(String artist, String album) async {
    try {
      final response = await _dio.get('', queryParameters: {
        'method': 'album.getinfo',
        'artist': artist,
        'album': album,
        'api_key': _apiKey,
        'format': 'json',
      });

      final data = response.data;
      if (data == null || data['album'] == null) {
        return {};
      }

      final a = data['album'];
      String imgUrl = '';
      final imgList = a['image'] as List<dynamic>?;
      if (imgList != null && imgList.isNotEmpty) {
        imgUrl = imgList.last['#text'] as String? ?? '';
      }

      final wiki = a['wiki'];
      final String summary = wiki != null ? wiki['summary'] as String? ?? '' : '';

      return {
        'name': a['name'] as String? ?? album,
        'artist': a['artist'] as String? ?? artist,
        'imageUrl': imgUrl,
        'summary': summary.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      };
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('Last.fm Album Info Error: ${e.toString()}');
    }
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
    throw SongUnavailableException('Last.fm service error: ${e.message}');
  }
}
