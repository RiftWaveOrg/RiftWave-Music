import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/routes/app_routes.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      if (!controller.hasSong.value) return const SizedBox.shrink();

      final song = controller.currentSong.value;
      if (song == null) return const SizedBox.shrink();

      return Dismissible(
        key: ValueKey('mini_player_${song.id}'),
        direction: DismissDirection.horizontal,
        background: const SizedBox.shrink(),
        onDismissed: (direction) {
          controller.clearQueue();
        },
        child: GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.player),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Obx(() => ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: LinearProgressIndicator(
                    value: controller.progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    minHeight: 2,
                  ),
                )),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [

                      Hero(
                        tag: 'album_art_${song.id}',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.primary.withAlpha(30),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: song.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title.isEmpty ? 'Unknown Title' : song.title,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist.isEmpty ? 'Unknown Artist' : song.artist,
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(120),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      Obx(() => IconButton(
                        icon: Icon(
                          controller.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: colorScheme.onSurface,
                          size: 28,
                        ),
                        onPressed: controller.togglePlayPause,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      )),

                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: colorScheme.onSurface.withAlpha(160),
                          size: 24,
                        ),
                        onPressed: controller.skipToNext,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideY(
            begin: 1,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ).fadeIn(duration: 300.ms),
        ),
      );
    });
  }
}
