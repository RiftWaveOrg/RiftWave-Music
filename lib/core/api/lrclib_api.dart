import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/api/exceptions/api_exceptions.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class LrcLibApi extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://lrclib.net/api',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static const String _lyricsBoxName = 'lyrics_box';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_lyricsBoxName)) {
      return await Hive.openBox(_lyricsBoxName);
    }
    return Hive.box(_lyricsBoxName);
  }

  Future<Map<String, String>> getLyrics(SongModel song) async {
    final box = await _getBox();

    final cached = box.get(song.id);
    if (cached != null && cached is Map) {
      return {
        'plain': cached['plain'] as String? ?? '',
        'synced': cached['synced'] as String? ?? '',
      };
    }

    try {
      final durationSeconds = (song.durationMs / 1000).round();
      final response = await _dio.get('/get', queryParameters: {
        'track_name': song.title,
        'artist_name': song.artist,
        'duration': durationSeconds,
      });

      final data = response.data;
      if (data == null) {
        return {'plain': '', 'synced': ''};
      }

      final plain = data['plainLyrics'] as String? ?? '';
      final synced = data['syncedLyrics'] as String? ?? '';

      final lyricsMap = {
        'plain': plain,
        'synced': synced,
      };

      await box.put(song.id, lyricsMap);

      return lyricsMap;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {

        final emptyMap = {'plain': '', 'synced': ''};
        await box.put(song.id, emptyMap);
        return emptyMap;
      }

      if (e.error is SocketException ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NoInternetException();
      }
      if (e.response?.statusCode == 429) {
        throw RateLimitException();
      }
      throw ParseException('LRCLIB API Error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException('Lyrics Fetch Error: ${e.toString()}');
    }
  }
}
