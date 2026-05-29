import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/core/api/lastfm_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';

class PlayerController extends GetxController {
  final RxBool isExpanded = false.obs;
  final RxBool showLyrics = false.obs;
  final RxInt selectedTab = 0.obs;

  final RxString artistBio = ''.obs;
  final RxList<SongModel> similarSongs = <SongModel>[].obs;

  final RxBool isLoadingBio = false.obs;
  final RxBool isLoadingSimilar = false.obs;

  late final AudioPlayerController _audioController;
  Worker? _songListener;

  void toggleLyrics() {
    showLyrics.value = !showLyrics.value;
  }

  void expand() => isExpanded.value = true;
  void collapse() => isExpanded.value = false;

  @override
  void onInit() {
    super.onInit();
    _audioController = Get.find<AudioPlayerController>();

    _songListener = ever<SongModel?>(_audioController.currentSong, (song) {
      if (song != null) {
        _fetchArtistBio(song.artist);
        _fetchSimilarSongs(song);
      } else {
        _clearData();
      }
    });

    final initialSong = _audioController.currentSong.value;
    if (initialSong != null) {
      _fetchArtistBio(initialSong.artist);
      _fetchSimilarSongs(initialSong);
    }
  }

  @override
  void onClose() {
    _songListener?.dispose();
    super.onClose();
  }

  void _clearData() {
    artistBio.value = '';
    similarSongs.clear();
  }

  Future<void> _fetchArtistBio(String artist) async {
    isLoadingBio.value = true;
    artistBio.value = '';
    try {
      final primaryArtist = _getPrimaryArtist(artist);
      debugPrint('PlayerController._fetchArtistBio: starting search for "$primaryArtist" (original: "$artist")');

      try {
        final saavn = Get.find<SaavnApi>();
        debugPrint('PlayerController._fetchArtistBio: trying JioSaavn for "$primaryArtist"');
        final artistId = await saavn.searchArtist(primaryArtist);
        if (artistId != null) {
          final details = await saavn.getArtistDetails(artistId);
          final bio = details['biography'] as String? ?? '';
          if (bio.isNotEmpty) {
            debugPrint('PlayerController._fetchArtistBio: JioSaavn bio loaded successfully (length: ${bio.length})');
            artistBio.value = bio;
            return;
          }
          debugPrint('PlayerController._fetchArtistBio: JioSaavn bio was empty');
        } else {
          debugPrint('PlayerController._fetchArtistBio: JioSaavn artist ID not found');
        }
      } catch (e) {
        debugPrint('PlayerController._fetchArtistBio JioSaavn Error: $e');
      }

      try {
        final lastfm = Get.find<LastFmApi>();
        debugPrint('PlayerController._fetchArtistBio: trying Last.fm for "$primaryArtist"');
        final bio = await lastfm.getArtistBio(primaryArtist);
        if (bio.isNotEmpty) {
          debugPrint('PlayerController._fetchArtistBio: Last.fm bio loaded successfully (length: ${bio.length})');
          artistBio.value = bio;
          return;
        }
        debugPrint('PlayerController._fetchArtistBio: Last.fm bio was empty');
      } catch (e) {
        debugPrint('PlayerController._fetchArtistBio Last.fm Error: $e');
      }

      debugPrint('PlayerController._fetchArtistBio: no biography available from any source');
      artistBio.value = 'No biography available for this artist.';
    } catch (e) {
      debugPrint('PlayerController._fetchArtistBio: outer catch error: $e');
      artistBio.value = 'No biography available for this artist.';
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

    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*VEVO$', caseSensitive: false), '');

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
}
