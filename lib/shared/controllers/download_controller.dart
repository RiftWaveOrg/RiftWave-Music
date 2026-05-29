import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';

class DownloadController extends GetxController {
  final _dio = Dio();
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 0);
  }

  Future<void> downloadSong(SongModel song) async {
    if (downloadProgress.containsKey(song.id)) return;
    downloadProgress[song.id] = 0.01;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${docDir.path}/downloads');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final savePath = '${saveDir.path}/${song.id}.mp3';
      
      
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      
      String audioUrl = '';
      if (song.source == MusicSource.youtube) {
        final yt = Get.find<YouTubeApi>();
        audioUrl = await yt.getStreamUrl(song.id);
      } else {
        final saavn = Get.find<SaavnApi>();
        audioUrl = await saavn.getStreamUrl(song.id);
      }

      if (audioUrl.isEmpty) throw Exception('No audio URL available for download');

      await _dio.download(
        audioUrl,
        savePath,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': '*/*',
            'Connection': 'keep-alive',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress[song.id] = received / total;
          }
        },
      );

      final downloadedSong = song.copyWith(
        isDownloaded: true,
        localPath: savePath,
        audioUrl: audioUrl,
      );

      final libraryController = Get.find<LibraryController>();
      await libraryController.addDownloadedSong(downloadedSong);

      downloadProgress.remove(song.id);
      
      Get.snackbar(
        'Download Complete', 
        '${song.title} has been downloaded.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('DownloadController: Failed to download song: $e');
      downloadProgress.remove(song.id);
      Get.snackbar(
        'Download Failed', 
        'Failed to download ${song.title}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> removeDownload(SongModel song) async {
    if (song.localPath != null) {
      try {
        final file = File(song.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('DownloadController: Failed to delete file: $e');
      }
    }
    
    final libraryController = Get.find<LibraryController>();
    await libraryController.removeDownloadedSong(song.id);
  }

  Future<void> clearAllDownloads() async {
    final libraryController = Get.find<LibraryController>();
    for (final song in libraryController.downloadedSongs) {
      if (song.localPath != null) {
        try {
          final file = File(song.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('DownloadController: Failed to delete file: $e');
        }
      }
    }
    
    
    final box = Hive.box<SongModel>('downloads_box');
    await box.clear();
    libraryController.downloadedSongs.clear();
  }
}
