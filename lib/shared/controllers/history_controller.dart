import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/database/models/history_model.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class HistoryController extends GetxController {
  static const String _historyBoxName = 'history_box';
  static const String _songsBoxName = 'history_songs_box';

  late Box<HistoryModel> _historyBox;
  late Box<SongModel> _songsBox;

  final RxList<SongModel> recentlyPlayed = <SongModel>[].obs;
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen(_historyBoxName)) {
        _historyBox = await Hive.openBox<HistoryModel>(_historyBoxName);
      } else {
        _historyBox = Hive.box<HistoryModel>(_historyBoxName);
      }

      if (!Hive.isBoxOpen(_songsBoxName)) {
        _songsBox = await Hive.openBox<SongModel>(_songsBoxName);
      } else {
        _songsBox = Hive.box<SongModel>(_songsBoxName);
      }

      isInitialized.value = true;
      loadRecentlyPlayed();
    } catch (e) {
      debugPrint('HistoryController: Failed to initialize Hive: $e');
    }
  }

  Future<void> addToHistory(SongModel song) async {
    if (!isInitialized.value) return;

    try {

      await _songsBox.put(song.id, song);

      final existingKeys = _historyBox.keys.where((key) {
        final entry = _historyBox.get(key);
        return entry?.songId == song.id;
      }).toList();

      for (final key in existingKeys) {
        await _historyBox.delete(key);
      }

      await _historyBox.add(HistoryModel(
        songId: song.id,
        playedAt: DateTime.now(),
      ));

      loadRecentlyPlayed();
    } catch (e) {
      debugPrint('HistoryController: Failed to add to history: $e');
    }
  }

  void loadRecentlyPlayed() {
    if (!isInitialized.value) return;

    try {
      final entries = _historyBox.values.toList();

      entries.sort((a, b) => b.playedAt.compareTo(a.playedAt));

      final List<SongModel> songs = [];
      for (final entry in entries) {
        final song = _songsBox.get(entry.songId);
        if (song != null) {
          songs.add(song);
        }
        if (songs.length >= 10) break;
      }

      recentlyPlayed.assignAll(songs);
    } catch (e) {
      debugPrint('HistoryController: Failed to load recently played: $e');
    }
  }
}
