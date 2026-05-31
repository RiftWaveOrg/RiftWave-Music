import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/api/lrclib_api.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/player/models/lyric_line.dart';
import 'package:riftwave_music/features/player/utils/lrc_parser.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

class LyricsController extends GetxController {
  final RxList<LyricLine> syncedLyrics = <LyricLine>[].obs;
  final RxString plainLyrics = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasSyncedLyrics = false.obs;
  final RxInt currentLineIndex = (-1).obs;
  final RxBool isAutoScrollPaused = false.obs;
  final RxInt syncOffsetMs = 0.obs;

  late final ScrollController scrollController;
  late final AudioPlayerController _audioController;

  Worker? _songListener;
  Worker? _positionListener;
  Worker? _scrollTriggerListener;
  Timer? _manualScrollTimer;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    _audioController = Get.find<AudioPlayerController>();

    _songListener = ever<SongModel?>(_audioController.currentSong, (song) {
      if (song != null) {
        _fetchLyrics(song);
      } else {
        _clearLyrics();
      }
    });

    _positionListener = ever<Duration>(_audioController.currentPosition, (position) {
      _updateActiveLineIndex(position);
    });

    _scrollTriggerListener = ever<int>(currentLineIndex, (_) {
      if (!isAutoScrollPaused.value) {
        scrollToActiveLine();
      }
    });

    final initialSong = _audioController.currentSong.value;
    if (initialSong != null) {
      _fetchLyrics(initialSong);
    }
  }

  @override
  void onClose() {
    _songListener?.dispose();
    _positionListener?.dispose();
    _scrollTriggerListener?.dispose();
    _manualScrollTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  void _clearLyrics() {
    syncedLyrics.clear();
    plainLyrics.value = '';
    hasSyncedLyrics.value = false;
    currentLineIndex.value = -1;
    isAutoScrollPaused.value = false;
    syncOffsetMs.value = 0;
    _manualScrollTimer?.cancel();
  }

  Future<void> _fetchLyrics(SongModel song) async {
    isLoading.value = true;
    _clearLyrics();
    try {
      final lrclib = Get.find<LrcLibApi>();
      final lyrics = await lrclib.getLyrics(song);

      final synced = lyrics['synced'] ?? '';
      final plain = lyrics['plain'] ?? '';

      if (synced.isNotEmpty) {
        final parsed = LrcParser.parse(synced);
        syncedLyrics.assignAll(parsed);
      }
      plainLyrics.value = plain;
      hasSyncedLyrics.value = syncedLyrics.isNotEmpty;

      _updateActiveLineIndex(_audioController.currentPosition.value);
    } catch (e) {
      debugPrint('LyricsController: LrcLib fetch failed ($e). Attempting fallback...');
      await _fetchLyricsFallback(song);
    } finally {
      isLoading.value = false;
    }
  }

  
  
  String _cleanTitle(String title) {
    
    String cleaned = title;
    final patterns = [
      RegExp(r'\s*[\(\[](official\s*(music\s*)?video|official\s*audio|lyrics?\s*video|audio|lyric|hd|hq|4k|visualizer|visualiser|animated\s*video|slowed\s*\+?\s*reverb)[\)\]]', caseSensitive: false),
      RegExp(r'\s*[\(\[]feat\.?[^\)\]]*[\)\]]', caseSensitive: false),
      RegExp(r'\s*[\(\[]ft\.?[^\)\]]*[\)\]]', caseSensitive: false),
      RegExp(r'\s*[\(\[]prod\.?[^\)\]]*[\)\]]', caseSensitive: false),
      RegExp(r'\s*[\(\[]from\s+"[^"]*"[^\)\]]*[\)\]]', caseSensitive: false),
      RegExp(r'\s*\|\s*.*$', caseSensitive: false),
      RegExp(r'\s+ft\.?\s+.*$', caseSensitive: false),
      RegExp(r'\s+feat\.?\s+.*$', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }
    return cleaned.trim();
  }

  Future<void> _fetchLyricsFallback(SongModel song) async {
    try {
      final dio = Get.find<LrcLibApi>().getDioForFallback();
      final cleanedTitle = _cleanTitle(song.title);
      final encodedArtist = Uri.encodeComponent(song.artist);
      final encodedTitle = Uri.encodeComponent(cleanedTitle);
      debugPrint('LyricsController: OVH fallback query: artist="${song.artist}", title="$cleanedTitle"');
      final res = await dio.get('https://api.lyrics.ovh/v1/$encodedArtist/$encodedTitle');
      
      final lyrics = res.data['lyrics'] as String?;
      if (lyrics != null && lyrics.isNotEmpty) {
        plainLyrics.value = lyrics;
        hasSyncedLyrics.value = false;
        debugPrint('LyricsController: Successfully fetched fallback lyrics from OVH.');
      } else {
        plainLyrics.value = '';
        hasSyncedLyrics.value = false;
      }
    } catch (e) {
      plainLyrics.value = '';
      hasSyncedLyrics.value = false;
      debugPrint('LyricsController: All lyrics fallbacks failed ($e).');
    }
  }

  void shiftLyrics(int ms) {
    syncOffsetMs.value += ms;
    _updateActiveLineIndex(_audioController.currentPosition.value);
  }

  void _updateActiveLineIndex(Duration position) {
    if (syncedLyrics.isEmpty) return;

    final adjustedPosition = position + Duration(milliseconds: syncOffsetMs.value);

    int activeIndex = -1;
    for (int i = 0; i < syncedLyrics.length; i++) {
      if (syncedLyrics[i].time <= adjustedPosition) {
        activeIndex = i;
      } else {
        break;
      }
    }

    if (currentLineIndex.value != activeIndex) {
      currentLineIndex.value = activeIndex;
    }
  }

  void scrollToActiveLine() {
    final index = currentLineIndex.value;
    if (index < 0 || index >= syncedLyrics.length) return;
    if (!scrollController.hasClients) return;

    final viewportHeight = scrollController.position.viewportDimension;
    const itemHeight = 52.0;
    final targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);

    scrollController.animateTo(
      targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void onUserScroll() {
    _manualScrollTimer?.cancel();
    isAutoScrollPaused.value = true;

    _manualScrollTimer = Timer(const Duration(seconds: 5), () {
      isAutoScrollPaused.value = false;
      scrollToActiveLine();
    });
  }

  void seekToLine(LyricLine line) {
    _audioController.seekTo(line.time);
  }
}
