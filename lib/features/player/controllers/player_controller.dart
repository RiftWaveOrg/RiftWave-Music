import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/core/api/lrclib_api.dart';
import 'package:riftwave_music/core/api/lastfm_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';

class LyricLine {
  final Duration time;
  final String text;
  LyricLine(this.time, this.text);
}

class PlayerController extends GetxController {
  final RxBool isExpanded = false.obs;
  final RxBool showLyrics = false.obs;
  final RxInt selectedTab = 0.obs;

  final RxString plainLyrics = ''.obs;
  final RxList<LyricLine> parsedLyrics = <LyricLine>[].obs;
  final RxString artistBio = ''.obs;
  final RxList<SongModel> similarSongs = <SongModel>[].obs;

  final RxBool isLoadingLyrics = false.obs;
  final RxBool isLoadingBio = false.obs;
  final RxBool isLoadingSimilar = false.obs;

  late final AudioPlayerController _audioController;
  late final ScrollController lyricsScrollController;
  Worker? _songListener;

  void toggleLyrics() {
    showLyrics.value = !showLyrics.value;
  }

  void expand() => isExpanded.value = true;
  void collapse() => isExpanded.value = false;

  @override
  void onInit() {
    super.onInit();
    lyricsScrollController = ScrollController();
    _audioController = Get.find<AudioPlayerController>();

    _songListener = ever<SongModel?>(_audioController.currentSong, (song) {
      if (song != null) {
        _fetchLyrics(song);
        _fetchArtistBio(song.artist);
        _fetchSimilarSongs(song);
      } else {
        _clearData();
      }
    });

    final initialSong = _audioController.currentSong.value;
    if (initialSong != null) {
      _fetchLyrics(initialSong);
      _fetchArtistBio(initialSong.artist);
      _fetchSimilarSongs(initialSong);
    }
  }

  @override
  void onClose() {
    _songListener?.dispose();
    lyricsScrollController.dispose();
    super.onClose();
  }

  void _clearData() {
    plainLyrics.value = '';
    parsedLyrics.clear();
    artistBio.value = '';
    similarSongs.clear();
  }

  Future<void> _fetchLyrics(SongModel song) async {
    isLoadingLyrics.value = true;
    plainLyrics.value = '';
    parsedLyrics.clear();
    try {
      final lrclib = Get.find<LrcLibApi>();
      final lyrics = await lrclib.getLyrics(song);

      final synced = lyrics['synced'] ?? '';
      final plain = lyrics['plain'] ?? '';

      if (synced.isNotEmpty) {
        parsedLyrics.assignAll(_parseLrc(synced));
      }
      plainLyrics.value = plain;
    } catch (e) {
      plainLyrics.value = 'Failed to load lyrics: $e';
    } finally {
      isLoadingLyrics.value = false;
    }
  }

  Future<void> _fetchArtistBio(String artist) async {
    isLoadingBio.value = true;
    artistBio.value = '';
    try {
      final primaryArtist = _getPrimaryArtist(artist);
      final saavn = Get.find<SaavnApi>();

      final artistId = await saavn.searchArtist(primaryArtist);
      if (artistId != null) {
        final details = await saavn.getArtistDetails(artistId);
        final bio = details['biography'] as String? ?? '';
        if (bio.isNotEmpty) {
          artistBio.value = bio;
          return;
        }
      }

      final lastfm = Get.find<LastFmApi>();
      final bio = await lastfm.getArtistBio(primaryArtist);
      artistBio.value = bio.isNotEmpty ? bio : 'No biography available for this artist.';
    } catch (e) {

      try {
        final primaryArtist = _getPrimaryArtist(artist);
        final lastfm = Get.find<LastFmApi>();
        final bio = await lastfm.getArtistBio(primaryArtist);
        artistBio.value = bio.isNotEmpty ? bio : 'No biography available for this artist.';
      } catch (lastFmError) {
        artistBio.value = 'Failed to load artist biography: $lastFmError';
      }
    } finally {
      isLoadingBio.value = false;
    }
  }

  Future<void> _fetchSimilarSongs(SongModel song) async {
    isLoadingSimilar.value = true;
    similarSongs.clear();
    try {
      final primaryArtist = _getPrimaryArtist(song.artist);
      final saavn = Get.find<SaavnApi>();

      final artistId = await saavn.searchArtist(primaryArtist);
      if (artistId != null) {
        final songs = await saavn.getArtistSongs(artistId);
        final filtered = songs.where((s) => s.title.toLowerCase() != song.title.toLowerCase()).toList();
        if (filtered.isNotEmpty) {
          similarSongs.assignAll(filtered);
          return;
        }
      }

      final searchResults = await saavn.searchSongs(primaryArtist);
      final filteredSearch = searchResults
          .where((s) => s.title.toLowerCase() != song.title.toLowerCase())
          .toList();
      if (filteredSearch.isNotEmpty) {
        similarSongs.assignAll(filteredSearch.take(10));
        return;
      }

      final yt = Get.find<YouTubeApi>();
      final ytResults = await yt.search('$primaryArtist songs');
      final filteredYt = ytResults
          .where((s) => s.title.toLowerCase() != song.title.toLowerCase())
          .toList();
      if (filteredYt.isNotEmpty) {
        similarSongs.assignAll(filteredYt.take(10));
        return;
      }

      final lastfm = Get.find<LastFmApi>();
      final songs = await lastfm.getSimilarSongs(primaryArtist, song.title);
      similarSongs.assignAll(songs);
    } catch (_) {

    } finally {
      isLoadingSimilar.value = false;
    }
  }

  String _getPrimaryArtist(String artist) {
    if (artist.isEmpty) return '';
    String cleaned = artist;
    final dividers = [
      RegExp(r'\bfeat\.?\b', caseSensitive: false),
      RegExp(r'\bft\.?\b', caseSensitive: false),
      '&',
      ',',
      'and',
      'And'
    ];
    for (final divider in dividers) {
      final parts = cleaned.split(divider);
      if (parts.isNotEmpty) {
        cleaned = parts[0];
      }
    }
    return cleaned.trim();
  }

  List<LyricLine> _parseLrc(String lrcText) {
    if (lrcText.isEmpty) return [];
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\](.*)$');

    for (final line in lrcText.split('\n')) {
      final trimmed = line.trim();
      final match = regExp.firstMatch(trimmed);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final secDouble = double.parse(match.group(2)!);
        final sec = secDouble.toInt();
        final ms = ((secDouble - sec) * 1000).toInt();
        final text = match.group(3)!.trim();

        final duration = Duration(minutes: min, seconds: sec, milliseconds: ms);
        lines.add(LyricLine(duration, text));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
