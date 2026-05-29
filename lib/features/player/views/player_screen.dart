import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:riftwave_music/core/audio/repeat_mode.dart';
import 'package:riftwave_music/core/utils/duration_formatter.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/player/controllers/player_controller.dart';
import 'package:riftwave_music/features/player/controllers/dynamic_color_controller.dart';
import 'package:riftwave_music/features/player/controllers/lyrics_controller.dart';
import 'package:riftwave_music/features/player/models/player_colors.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/shared/controllers/download_controller.dart';
import 'package:riftwave_music/shared/widgets/playlist_selector_sheet.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:riftwave_music/features/player/widgets/wavy_seekbar.dart';
import 'package:riftwave_music/shared/widgets/download_progress_indicator.dart';
import 'package:riftwave_music/shared/widgets/marquee_text.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riftwave_music/shared/controllers/video_player_controller.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _likeController;
  late final AudioPlayerController _audioController;
  late final DynamicColorController _colorController;
  late final PlayerController _playerController;
  late final LyricsController _lyricsController;
  late final ScrollController _pageScrollController;
  final GlobalKey _lyricsKey = GlobalKey();
  final GlobalKey _bioKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageScrollController = ScrollController();
    _audioController = Get.find<AudioPlayerController>();
    _colorController = Get.find<DynamicColorController>();
    _playerController = Get.find<PlayerController>();
    _lyricsController = Get.find<LyricsController>();

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
      value: 1.0,
    );

    final song = _audioController.currentSong.value;
    if (song != null && song.thumbnailUrl.isNotEmpty) {
      _colorController.extractFromImageUrl(song.thumbnailUrl);
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSongDetailsDialog(BuildContext context, SongModel song, PlayerColors colors) {
    Get.dialog(
      AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'SONG DETAILS',
          style: TextStyle(
            color: colors.accent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Title', song.title, colors),
            const SizedBox(height: 12),
            _detailRow('Artist', song.artist, colors),
            const SizedBox(height: 12),
            _detailRow('Source', song.source == MusicSource.youtube ? 'YouTube' : 'JioSaavn', colors),
            const SizedBox(height: 12),
            _detailRow('Song ID', song.id, colors),
            const SizedBox(height: 12),
            if (song.audioUrl.isNotEmpty) ...[
              _detailRow('Stream URL', song.audioUrl, colors, isUrl: true),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, PlayerColors colors, {bool isUrl = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
          ),
          maxLines: isUrl ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showQueueSheet(BuildContext context, PlayerColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Obx(() {
            final queue = _audioController.queue;
            final currentIndex = _audioController.currentQueueIndex.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLAY QUEUE',
                      style: TextStyle(
                        color: colors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (queue.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _audioController.clearQueue();
                          Get.back();
                        },
                        icon: Icon(Icons.delete_sweep_rounded, color: colors.textSecondary, size: 18),
                        label: Text('Clear', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: colors.textSecondary.withAlpha(20)),
                const SizedBox(height: 12),
                if (queue.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Queue is empty',
                        style: TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: ReorderableListView.builder(
                        itemCount: queue.length,
                        physics: const BouncingScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          _audioController.reorderQueue(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final song = queue[index];
                          final isPlaying = index == currentIndex;

                          return Dismissible(
                            key: ValueKey('${song.id}_$index'),
                            direction: DismissDirection.endToStart,
                            background: const SizedBox.shrink(),
                            onDismissed: (direction) {
                              _audioController.removeFromQueue(index);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isPlaying ? colors.accent.withAlpha(25) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: colors.accent.withAlpha(15),
                                    child: song.thumbnailUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: song.thumbnailUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Icon(Icons.music_note_rounded, color: colors.accent),
                                          )
                                        : Icon(Icons.music_note_rounded, color: colors.accent),
                                  ),
                                ),
                                title: Text(
                                  song.title,
                                  style: TextStyle(
                                    color: isPlaying ? colors.accent : colors.textPrimary,
                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  song.artist,
                                  style: TextStyle(
                                    color: isPlaying ? colors.accent.withAlpha(180) : colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlaying)
                                      Icon(Icons.volume_up_rounded, color: colors.accent, size: 20),
                                    const SizedBox(width: 12),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(Icons.drag_handle_rounded, color: colors.textSecondary.withAlpha(100), size: 20),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _audioController.playFromQueue(index);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          }),
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, PlayerColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                'SLEEP TIMER',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...[
              ('15 minutes', const Duration(minutes: 15)),
              ('30 minutes', const Duration(minutes: 30)),
              ('45 minutes', const Duration(minutes: 45)),
              ('1 hour', const Duration(hours: 1)),
            ].map((option) => ListTile(
                  title: Text(option.$1, style: TextStyle(color: colors.textPrimary)),
                  leading: Icon(Icons.timer_outlined, color: colors.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    _audioController.setSleepTimer(option.$2);
                    Get.back();
                  },
                )),
            ListTile(
              title: Text('End of track', style: TextStyle(color: colors.textPrimary)),
              leading: Icon(Icons.music_off_outlined, color: colors.accent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                _audioController.setSleepTimerEndOfTrack();
                Get.back();
              },
            ),
            if (_audioController.sleepTimerRemaining.value != null)
              ListTile(
                title: Text('Cancel timer', style: TextStyle(color: Colors.redAccent.shade100)),
                leading: Icon(Icons.cancel_outlined, color: Colors.redAccent.shade100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  _audioController.cancelSleepTimer();
                  Get.back();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      final colors = _colorController.playerColors.value;
      final song = _audioController.currentSong.value;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.6, 1.0],
              colors: [
                colors.gradientTop,
                colors.gradientMid,
                colors.background,
                colors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _pageScrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildHeader(colors, song),
                    const SizedBox(height: 24),
                    _buildAlbumArt(colors, song, screenSize),
                    const SizedBox(height: 32),
                    _buildSongInfo(colors, song),
                    const SizedBox(height: 24),
                    _buildSeekbar(colors),
                    const SizedBox(height: 16),
                    _buildControls(colors),
                    const SizedBox(height: 32),
                    _buildLyricsSection(colors),
                    const SizedBox(height: 24),
                    _buildBioSection(colors),
                    const SizedBox(height: 24),
                    _buildRecommendedSection(colors),
                    SizedBox(height: bottomPadding + 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(PlayerColors colors, SongModel? song) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: colors.textPrimary),
            onPressed: () => Get.back(),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              if (song != null)
                Text(
                  song.source == MusicSource.youtube ? 'YouTube' : 'JioSaavn',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colors.textPrimary),
            color: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  if (song != null) {
                    Share.share('Check out "${song.title}" by ${song.artist} on RiftWave Music!');
                  }
                  break;
                case 'sleep_timer':
                  _showSleepTimerSheet(context, colors);
                  break;
                case 'lyrics':
                  _scrollToSection(_lyricsKey);
                  break;
                case 'bio':
                  _scrollToSection(_bioKey);
                  break;
                case 'details':
                  if (song != null) {
                    _showSongDetailsDialog(context, song, colors);
                  }
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: colors.textPrimary, size: 20),
                    const SizedBox(width: 12),
                    Text('Share', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sleep_timer',
                child: Obx(() {
                  final remaining = _audioController.sleepTimerRemaining.value;
                  final hasTimer = remaining != null;
                  return Row(
                    children: [
                      Icon(Icons.timer_outlined, color: hasTimer ? colors.accent : colors.textPrimary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        hasTimer
                            ? (remaining.inSeconds < 0 ? 'Sleep: End of track' : 'Sleep: ${DurationFormatter.format(remaining)}')
                            : 'Sleep Timer',
                        style: TextStyle(color: hasTimer ? colors.accent : colors.textPrimary),
                      ),
                    ],
                  );
                }),
              ),
              PopupMenuItem(
                value: 'lyrics',
                child: Row(
                  children: [
                    Icon(Icons.lyrics_outlined, color: colors.textPrimary, size: 20),
                    const SizedBox(width: 12),
                    Text('Go to Lyrics', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bio',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: colors.textPrimary, size: 20),
                    const SizedBox(width: 12),
                    Text('Go to Artist Bio', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.textPrimary, size: 20),
                    const SizedBox(width: 12),
                    Text('Song Details', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(PlayerColors colors, SongModel? song, Size screenSize) {
    final artSize = screenSize.width - 80;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.glowColor.withAlpha(128),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Hero(
            tag: 'album_art_${song?.id ?? 'none'}',
            child: Obx(() {
              final videoController = Get.find<VideoPlayerController>();
              final isVideo = videoController.isVideoAvailable.value;
              final isHandling = videoController.isHandlingPlayback;

              if (isHandling) {
                return GestureDetector(
                  onTap: () {
                    
                    Get.toNamed('/fullscreen_video');
                  },
                  child: AspectRatio(
                    aspectRatio: videoController.videoAspectRatio.value,
                    child: Stack(
                      fit: StackFit.expand,
                        children: [
                        
                        if (song != null && song.thumbnailUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            fit: BoxFit.cover,
                          ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                          child: Container(
                            color: Colors.black.withAlpha(120),
                          ),
                        ),
                        
                        Video(
                          controller: videoController.videoController,
                          controls: NoVideoControls,
                          fit: BoxFit.contain,
                        ),
                        
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(128),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: song != null && song.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        key: ValueKey(song.thumbnailUrl),
                        imageUrl: song.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: artSize,
                        height: artSize,
                        placeholder: (_, __) => _artPlaceholder(colors, artSize),
                        errorWidget: (_, __, ___) => _artPlaceholder(colors, artSize),
                      )
                    : _artPlaceholder(colors, artSize),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(PlayerColors colors, SongModel? song) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
                child: MarqueeText(
                  text: song?.title ?? 'No Song Playing',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                song?.artist ?? 'Search for music',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (song != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.playlist_add_rounded, color: colors.textSecondary, size: 26),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PlaylistSelectorSheet(song: song),
                  );
                },
              ),
              Obx(() {
                final downloader = Get.find<DownloadController>();
                final libraryController = Get.find<LibraryController>();
                
                downloader.downloadProgress.length;
                libraryController.downloadedSongs.length;
                
                final progress = downloader.downloadProgress[song.id];
                if (progress != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DownloadProgressIndicator(
                      progress: progress,
                      color: colors.accent,
                    ),
                  );
                } else if (song.isDownloaded || libraryController.downloadedSongs.any((s) => s.id == song.id)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.download_done_rounded, color: colors.accent, size: 26),
                  );
                }
                
                return IconButton(
                  icon: Icon(Icons.download_rounded, color: colors.textSecondary, size: 26),
                  onPressed: () => downloader.downloadSong(song),
                );
              }),
              Obx(() {
                final libraryController = Get.find<LibraryController>();
                libraryController.likedSongs.length; 
                final liked = libraryController.isLiked(song.id);
                return GestureDetector(
                  onTap: () {
                    libraryController.toggleLike(song);
                    _likeController.forward(from: 0.8).then((_) {
                      _likeController.animateTo(1.0, curve: Curves.elasticOut);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: ScaleTransition(
                      scale: _likeController,
                      child: Icon(
                        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: liked ? colors.accent : colors.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildSeekbar(PlayerColors colors) {
    return Obx(() {
      final pos = _audioController.currentPosition.value;
      final dur = _audioController.totalDuration.value;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: WavySeekBar(
              position: pos,
              duration: dur,
              onChanged: (value) {
                _audioController.seekTo(value);
              },
              activeColor: colors.seekbarActive,
              inactiveColor: colors.seekbarInactive,
              thumbColor: colors.accent,
              isPlaying: _audioController.isPlaying.value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DurationFormatter.format(pos),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                Text(
                  DurationFormatter.format(dur),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildVolumeButton(PlayerColors colors) {
    return PopupMenuButton<double>(
      icon: Obx(() {
        final vol = _audioController.volume.value;
        IconData icon = Icons.volume_mute_rounded;
        if (vol > 0.6) {
          icon = Icons.volume_up_rounded;
        } else if (vol > 0.1) {
          icon = Icons.volume_down_rounded;
        } else if (vol > 0) {
          icon = Icons.volume_mute_rounded;
        } else {
          icon = Icons.volume_off_rounded;
        }
        return Icon(icon, color: colors.textPrimary);
      }),
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, -90),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Volume',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => Row(
                children: [
                  Icon(Icons.volume_down_rounded, color: colors.textSecondary, size: 16),
                  Expanded(
                    child: SizedBox(
                      width: 130,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          activeTrackColor: colors.accent,
                          inactiveTrackColor: colors.seekbarInactive,
                          thumbColor: colors.accent,
                          overlayColor: colors.accent.withAlpha(20),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        ),
                        child: Slider(
                          value: _audioController.volume.value,
                          onChanged: (v) => _audioController.setVolume(v),
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, color: colors.textSecondary, size: 16),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(PlayerColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVolumeButton(colors),
        Obx(() => IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                color: _audioController.shuffleMode.value
                    ? colors.accent
                    : colors.textSecondary,
              ),
              onPressed: _audioController.toggleShuffle,
            )),
        IconButton(
          icon: Icon(
            Icons.skip_previous_rounded,
            color: colors.textPrimary,
            size: 34,
          ),
          onPressed: () { HapticFeedback.lightImpact(); _audioController.skipToPrevious(); },
        ),
        Obx(() {
          final bool isLoading = _audioController.isBuffering.value ||
              (Get.isRegistered<VideoPlayerController>() && Get.find<VideoPlayerController>().isVideoLoading.value);
          final bool isPlaying = _audioController.isPlaying.value;

          return GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); _audioController.togglePlayPause(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: colors.glowColor.withAlpha(100),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: _contrastTextFor(colors.accent),
                              strokeWidth: 3.5,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey('icon_$isPlaying'),
                            color: _contrastTextFor(colors.accent),
                            size: 32,
                          ),
                  ),
                ),
              ),
            );
        }),
        IconButton(
          icon: Icon(
            Icons.skip_next_rounded,
            color: colors.textPrimary,
            size: 34,
          ),
          onPressed: () { HapticFeedback.lightImpact(); _audioController.skipToNext(); },
        ),
        Obx(() {
          final mode = _audioController.repeatMode.value;
          final isActive = mode != RiftWaveRepeatMode.off;
          return IconButton(
            icon: Icon(
              mode == RiftWaveRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: isActive ? colors.accent : colors.textSecondary,
            ),
            onPressed: _audioController.cycleRepeatMode,
          );
        }),
        IconButton(
          icon: Icon(
            Icons.queue_music_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => _showQueueSheet(context, colors),
        ),
      ],
    );
  }

  Widget _buildLyricsSection(PlayerColors colors) {
    return AnimatedContainer(
      key: _lyricsKey,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withAlpha(15)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'LYRICS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.accent,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.textSecondary.withAlpha(25)),
          const SizedBox(height: 12),
          _buildLyricsContent(colors),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(PlayerColors colors) {
    return Obx(() {
      if (_lyricsController.isLoading.value) {
        return _loadingPlaceholder(colors);
      }

      final containerHeight = MediaQuery.of(context).size.height * 0.40;

      if (_lyricsController.hasSyncedLyrics.value) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_lyricsController.isAutoScrollPaused.value) {
            _lyricsController.scrollToActiveLine();
          }
        });

        return SizedBox(
          height: containerHeight,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction != ScrollDirection.idle) {
                _lyricsController.onUserScroll();
              }
              return false;
            },
            child: ListView.builder(
              controller: _lyricsController.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              itemCount: _lyricsController.syncedLyrics.length,
              itemBuilder: (context, index) {
                final line = _lyricsController.syncedLyrics[index];

                return Obx(() {
                  final isActive = index == _lyricsController.currentLineIndex.value;

                  return SizedBox(
                    height: 52.0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _lyricsController.seekToLine(line),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            color: isActive ? colors.accent : colors.textSecondary.withAlpha(115),
                            fontSize: isActive ? 20.0 : 15.0,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text(
                              line.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        );
      }

      if (_lyricsController.plainLyrics.value.isNotEmpty) {
        return SizedBox(
          height: containerHeight,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: Text(
                _lyricsController.plainLyrics.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.8,
                  letterSpacing: 0.5,
                  color: colors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: containerHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://lottie.host/81a953e5-827d-45db-99c0-62e92c63eb45/tD36e3Gz4k.json',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent.withAlpha(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withAlpha(25),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.music_off_rounded,
                      size: 32,
                      color: colors.accent,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'No lyrics found.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary.withAlpha(180),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBioSection(PlayerColors colors) {
    return AnimatedContainer(
      key: _bioKey,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withAlpha(15)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'ARTIST BIO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.accent,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.textSecondary.withAlpha(25)),
          const SizedBox(height: 12),
          Obx(() {
            if (_playerController.isLoadingBio.value) {
              return _loadingPlaceholder(colors);
            }
            if (_playerController.artistBio.value.isEmpty) {
              return _messagePlaceholder('No biography available.', colors);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                _playerController.artistBio.value,
                style: TextStyle(
                  height: 1.6,
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(PlayerColors colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withAlpha(15)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'RECOMMENDED TRACKS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.accent,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.textSecondary.withAlpha(25)),
          const SizedBox(height: 12),
          Obx(() {
            if (_playerController.isLoadingSimilar.value) {
              return _loadingPlaceholder(colors);
            }
            if (_playerController.similarSongs.isEmpty) {
              return _messagePlaceholder('No recommendations found.', colors);
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _playerController.similarSongs.length,
              itemBuilder: (context, index) {
                final song = _playerController.similarSongs[index];
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colors.accent.withAlpha(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(Icons.music_note_rounded, color: colors.accent),
                          )
                        : Icon(Icons.music_note_rounded, color: colors.accent),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_circle_outline_rounded, color: colors.accent),
                    onPressed: () => _audioController.playSong(song),
                  ),
                  onTap: () => _audioController.playSong(song),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _loadingPlaceholder(PlayerColors colors) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
      ),
    );
  }

  Widget _messagePlaceholder(String message, PlayerColors colors) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _artPlaceholder(PlayerColors colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withAlpha(100),
            colors.surface,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: colors.accent.withAlpha(120),
        ),
      ),
    );
  }

  Color _contrastTextFor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({super.key, required this.text, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final currentScroll = _scrollController.position.pixels;
      double nextScroll = currentScroll + 1.0;

      if (nextScroll >= maxScroll) {
        nextScroll = 0.0;
        _scrollController.jumpTo(0.0);
      } else {
        _scrollController.jumpTo(nextScroll);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
