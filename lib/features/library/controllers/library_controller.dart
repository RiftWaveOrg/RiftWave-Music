import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/database/models/playlist_model.dart';
import 'package:riftwave_music/core/database/models/history_model.dart';

class LibraryController extends GetxController {
  static const String _likedBoxName = 'liked_songs_box';
  static const String _playlistsBoxName = 'playlists_box';
  static const String _downloadsBoxName = 'downloads_box';
  static const String _historyBoxName = 'history_box';
  static const String _historySongsBoxName = 'history_songs_box';

  late Box<SongModel> _likedBox;
  late Box<PlaylistModel> _playlistsBox;
  late Box<SongModel> _downloadsBox;
  late Box<HistoryModel> _historyBox;
  late Box<SongModel> _historySongsBox;

  final RxList<SongModel> likedSongs = <SongModel>[].obs;
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxList<SongModel> downloadedSongs = <SongModel>[].obs;
  final RxList<SongModel> history = <SongModel>[].obs;

  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _likedBox = await _openBox<SongModel>(_likedBoxName);
      _playlistsBox = await _openBox<PlaylistModel>(_playlistsBoxName);
      _downloadsBox = await _openBox<SongModel>(_downloadsBoxName);
      _historyBox = await _openBox<HistoryModel>(_historyBoxName);
      _historySongsBox = await _openBox<SongModel>(_historySongsBoxName);

      isInitialized.value = true;
      _loadAllData();
    } catch (e) {
      debugPrint('LibraryController: Failed to initialize Hive: $e');
    }
  }

  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return await Hive.openBox<T>(name);
  }

  void _loadAllData() {
    likedSongs.assignAll(_likedBox.values.toList().reversed);
    
    final sortedPlaylists = _playlistsBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    playlists.assignAll(sortedPlaylists);

    downloadedSongs.assignAll(_downloadsBox.values.toList().reversed);

    _loadHistory();
  }

  void _loadHistory() {
    final entries = _historyBox.values.toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    final List<SongModel> songs = [];
    for (final entry in entries) {
      final song = _historySongsBox.get(entry.songId);
      if (song != null) {
        songs.add(song);
      } else {
        debugPrint('LibraryController: _loadHistory WARNING - Missing song metadata for ${entry.songId}');
      }
    }
    debugPrint('LibraryController: _loadHistory loaded ${songs.length} songs out of ${entries.length} entries.');
    history.assignAll(songs);
  }

  // --- LIKED SONGS ---

  bool isLiked(String songId) => _likedBox.containsKey(songId);

  Future<void> toggleLike(SongModel song) async {
    if (!isInitialized.value) return;
    
    if (isLiked(song.id)) {
      await _likedBox.delete(song.id);
      likedSongs.removeWhere((s) => s.id == song.id);
    } else {
      final clonedSong = song.copyWith();
      await _likedBox.put(song.id, clonedSong);
      likedSongs.insert(0, clonedSong);
    }
  }

  // --- PLAYLISTS ---

  Future<void> createPlaylist(String name, {String description = ''}) async {
    if (!isInitialized.value || name.trim().isEmpty) return;
    
    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description.trim(),
    );
    
    await _playlistsBox.put(playlist.id, playlist);
    playlists.insert(0, playlist);
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    if (!isInitialized.value) return;
    
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      if (!playlist.songIds.contains(song.id)) {
        playlist.songIds.add(song.id);
        playlist.updatedAt = DateTime.now();
        // Just store the song metadata in a general cache or history box so it can be retrieved?
        // Actually, custom playlists store songIds. We need the song models!
        // The prompt says we store songIds. Let's make sure we save the song in historySongsBox so it's retrievable.
        await _historySongsBox.put(song.id, song.copyWith());
        await playlist.save();
        
        final idx = playlists.indexWhere((p) => p.id == playlist.id);
        if (idx != -1) playlists[idx] = playlist;
        playlists.refresh();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      playlist.songIds.remove(songId);
      playlist.updatedAt = DateTime.now();
      await playlist.save();
      playlists.refresh();
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    if (newName.trim().isEmpty) return;
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      playlist.name = newName.trim();
      playlist.updatedAt = DateTime.now();
      await playlist.save();
      playlists.refresh();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistsBox.delete(playlistId);
    playlists.removeWhere((p) => p.id == playlistId);
  }
  
  List<SongModel> getSongsForPlaylist(PlaylistModel playlist) {
    final List<SongModel> songs = [];
    for (final id in playlist.songIds) {
      final song = _historySongsBox.get(id); // Use history box as a general song cache
      if (song != null) songs.add(song);
    }
    return songs;
  }
  
  Future<void> reorderPlaylist(String playlistId, int oldIndex, int newIndex) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = playlist.songIds.removeAt(oldIndex);
      playlist.songIds.insert(newIndex, item);
      playlist.updatedAt = DateTime.now();
      await playlist.save();
      playlists.refresh();
    }
  }

  // --- HISTORY ---

  Future<void> addToHistory(SongModel song) async {
    if (!isInitialized.value) {
      debugPrint('LibraryController: addToHistory aborted - not initialized');
      return;
    }

    try {
      debugPrint('LibraryController: Attempting to add ${song.id} to history');
      await _historySongsBox.put(song.id, song.copyWith());

      // Skip duplicate if within last 5 minutes
      if (history.isNotEmpty && history.first.id == song.id) {
        final lastEntry = _historyBox.values.toList()
          ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
        if (lastEntry.isNotEmpty) {
          final timeDiff = DateTime.now().difference(lastEntry.first.playedAt);
          if (timeDiff.inMinutes < 5) {
            debugPrint('LibraryController: Skipped adding to history (duplicate within 5 mins)');
            return;
          }
        }
      }

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
      
      debugPrint('LibraryController: HistoryModel added to _historyBox. Total items: ${_historyBox.length}');

      // Enforce 200 limit
      if (_historyBox.length > 200) {
        final allEntries = _historyBox.values.toList()
          ..sort((a, b) => a.playedAt.compareTo(b.playedAt)); // oldest first
        final toDelete = allEntries.take(_historyBox.length - 200);
        for (final entry in toDelete) {
          await entry.delete();
        }
      }
      
      _loadHistory();
    } catch (e) {
      debugPrint('LibraryController: Error adding to history: $e');
    }
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
    history.clear();
  }

  Future<void> removeFromHistory(String songId) async {
    final existingKeys = _historyBox.keys.where((key) {
      final entry = _historyBox.get(key);
      return entry?.songId == songId;
    }).toList();

    for (final key in existingKeys) {
      await _historyBox.delete(key);
    }
    history.removeWhere((s) => s.id == songId);
  }

  // --- DOWNLOADS (Integration with DownloadController) ---

  Future<void> addDownloadedSong(SongModel song) async {
    await _downloadsBox.put(song.id, song.copyWith());
    if (!downloadedSongs.any((s) => s.id == song.id)) {
      downloadedSongs.insert(0, song);
    } else {
      final idx = downloadedSongs.indexWhere((s) => s.id == song.id);
      downloadedSongs[idx] = song;
    }
  }

  Future<void> removeDownloadedSong(String songId) async {
    await _downloadsBox.delete(songId);
    downloadedSongs.removeWhere((s) => s.id == songId);
    // Also remove file via IO (handled in DownloadController)
  }
}
