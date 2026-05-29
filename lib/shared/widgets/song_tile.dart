import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/download_controller.dart';
import 'package:riftwave_music/shared/widgets/playlist_selector_sheet.dart';
import 'package:riftwave_music/shared/widgets/download_progress_indicator.dart';

class SongTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumbnailUrl!,
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
                      title,
                      style: TextStyle(
                        color: isPlaying
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
                      artist,
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
                  if (trailing != null) trailing!,
                  if (song != null) _buildLibraryActions(context, colorScheme),
                  if (song == null && trailing == null)
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
    );
  }

  Widget _buildLibraryActions(BuildContext context, ColorScheme colorScheme) {
    final library = Get.find<LibraryController>();
    final downloader = Get.find<DownloadController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          // Accessing the RxList length forces Obx tracking
          library.likedSongs.length;
          final isLiked = library.isLiked(song!.id);
          return IconButton(
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? Colors.red : colorScheme.onSurface.withAlpha(100),
              size: 20,
            ),
            onPressed: () => library.toggleLike(song!),
          );
        }),
        PopupMenuButton<String>(
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
                builder: (context) => PlaylistSelectorSheet(song: song!),
              );
            } else if (value == 'download') {
              downloader.downloadSong(song!);
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
              value: 'download',
              child: Row(
                children: [
                  Obx(() {
                    // Force GetX registration
                    downloader.downloadProgress.length;
                    library.downloadedSongs.length;
                    
                    final progress = downloader.downloadProgress[song!.id];
                    if (progress != null) {
                      return DownloadProgressIndicator(
                        progress: progress,
                        color: colorScheme.primary,
                      );
                    } else if (song!.isDownloaded || library.downloadedSongs.any((s) => s.id == song!.id)) {
                      return const Icon(Icons.download_done_rounded, size: 20, color: Colors.green);
                    }
                    return const Icon(Icons.download_rounded, size: 20);
                  }),
                  const SizedBox(width: 12),
                  const Text('Download'),
                ],
              ),
            ),
          ],
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
