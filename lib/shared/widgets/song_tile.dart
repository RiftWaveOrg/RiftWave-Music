import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/download_controller.dart';
import 'package:riftwave_music/shared/widgets/playlist_selector_sheet.dart';
import 'package:riftwave_music/shared/widgets/download_progress_indicator.dart';

class SongTile extends StatefulWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isPlaying;
  final SongModel? song;

  const SongTile({
    super.key,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    this.onTap,
    this.trailing,
    this.isPlaying = false,
    this.song,
  });

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  bool _isPressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Song: ${widget.title} by ${widget.artist}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          onHighlightChanged: (isHighlighted) {
            setState(() {
              _isPressed = isHighlighted;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
                          ),
                        )
                      : _buildPlaceholder(colorScheme),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.isPlaying
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.artist,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(120),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.trailing != null) widget.trailing!,
                    if (widget.song != null) _buildLibraryActions(context, colorScheme),
                    if (widget.song == null && widget.trailing == null)
                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: colorScheme.onSurface.withAlpha(100),
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate(target: _isPressed ? 1 : 0).scaleXY(end: 0.96, duration: 150.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildLibraryActions(BuildContext context, ColorScheme colorScheme) {
    final library = Get.find<LibraryController>();
    final downloader = Get.find<DownloadController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          library.likedSongs.length;
          final isLiked = library.isLiked(widget.song!.id);
          
          return Semantics(
            label: isLiked ? 'Unlike song' : 'Like song',
            button: true,
            child: IconButton(
              icon: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.red : colorScheme.onSurface.withAlpha(100),
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                library.toggleLike(widget.song!);
              },
            ).animate(key: ValueKey(isLiked))
             .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms),
          );
        }),
        Semantics(
          label: 'More options',
          button: true,
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurface.withAlpha(100),
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'playlist') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => PlaylistSelectorSheet(song: widget.song!),
                );
              } else if (value == 'download') {
                HapticFeedback.lightImpact();
                downloader.downloadSong(widget.song!);
              } else if (value == 'remove_download') {
                HapticFeedback.lightImpact();
                downloader.removeDownload(widget.song!);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Add to Playlist'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: (widget.song!.isDownloaded || library.downloadedSongs.any((s) => s.id == widget.song!.id)) ? 'remove_download' : 'download',
                child: Row(
                  children: [
                    Obx(() {
                      downloader.downloadProgress.length;
                      library.downloadedSongs.length;
                      
                      final progress = downloader.downloadProgress[widget.song!.id];
                      if (progress != null) {
                        return DownloadProgressIndicator(
                          progress: progress,
                          color: colorScheme.primary,
                        ).animate().fadeIn().scale();
                      } else if (widget.song!.isDownloaded || library.downloadedSongs.any((s) => s.id == widget.song!.id)) {
                        return const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red)
                               .animate().scale(curve: Curves.elasticOut, duration: 500.ms);
                      }
                      return const Icon(Icons.download_rounded, size: 20);
                    }),
                    const SizedBox(width: 12),
                    Obx(() {
                      final isDownloaded = widget.song!.isDownloaded || library.downloadedSongs.any((s) => s.id == widget.song!.id);
                      return Text(isDownloaded ? 'Remove Download' : 'Download', style: TextStyle(color: isDownloaded ? Colors.red : null));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: colorScheme.primary.withAlpha(100),
        size: 22,
      ),
    );
  }
}
