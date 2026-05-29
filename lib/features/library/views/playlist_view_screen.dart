import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/shared/widgets/song_tile.dart';
import 'package:riftwave_music/shared/widgets/mini_player.dart';
import 'package:riftwave_music/core/database/models/playlist_model.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class PlaylistViewScreen extends StatelessWidget {
  final bool isLikedSongs;
  final bool isDownloadedSongs;
  final PlaylistModel? playlist;

  const PlaylistViewScreen({
    super.key,
    this.isLikedSongs = false,
    this.isDownloadedSongs = false,
    this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final library = Get.find<LibraryController>();
    final player = Get.find<AudioPlayerController>();

    final title = isLikedSongs
        ? 'Liked Songs'
        : isDownloadedSongs
            ? 'Downloaded Songs'
            : playlist?.name ?? 'Playlist';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const SafeArea(
        top: false,
        child: MiniPlayer(),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        List<SongModel> songs = [];
        if (isLikedSongs) {
          songs = library.likedSongs.toList();
        } else if (isDownloadedSongs) {
          songs = library.downloadedSongs.toList();
        } else if (playlist != null) {
          library.playlists.length; 
          
          
          final updatedPlaylist = library.playlists.firstWhereOrNull((p) => p.id == playlist!.id) ?? playlist!;
          songs = library.getSongsForPlaylist(updatedPlaylist);
        }

        if (songs.isEmpty) {
          return Center(
            child: Text(
              'No songs here yet.',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
            ),
          );
        }

        final latestImage = songs.isNotEmpty ? songs.first.thumbnailUrl : '';

        return Stack(
          children: [
            if (latestImage.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: latestImage,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ),
            if (latestImage.isNotEmpty)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    color: colorScheme.surface.withAlpha(180),
                  ),
                ),
              ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withAlpha(40),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: latestImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: latestImage,
                                      width: 220,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => _buildFallbackIcon(colorScheme),
                                    )
                                  : _buildFallbackIcon(colorScheme),
                            ),
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                        const SizedBox(height: 8),
                        Text(
                          isLikedSongs ? 'Your Favorites' : 'Custom Playlist',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withAlpha(180),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Playlist • ${songs.length} tracks',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(130),
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: songs.isEmpty
                                  ? null
                                  : () {
                                      player.playAll(songs, startIndex: 0);
                                    },
                              icon: const Icon(Icons.play_arrow_rounded, size: 28),
                              label: const Text(
                                'PLAY ALL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
                isLikedSongs
                    ? SliverPadding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = songs[index];
                              return SongTile(
                                title: song.title,
                                artist: song.artist,
                                thumbnailUrl: song.thumbnailUrl,
                                isPlaying: player.currentSong.value?.id == song.id && player.isPlaying.value,
                                onTap: () {
                                  player.playAll(songs, startIndex: index);
                                },
                                song: song,
                              );
                            },
                            childCount: songs.length,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        sliver: SliverReorderableList(
                          itemCount: songs.length,
                          onReorder: (oldIndex, newIndex) {
                            if (playlist != null) {
                              library.reorderPlaylist(playlist!.id, oldIndex, newIndex);
                            }
                          },
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('playlist_${playlist?.id}_song_${song.id}'),
                              index: index,
                              child: Dismissible(
                                key: ValueKey('dismiss_playlist_${playlist?.id}_song_${song.id}'),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) {
                                  if (playlist != null) {
                                    library.removeSongFromPlaylist(playlist!.id, song.id);
                                  }
                                },
                                background: Container(
                                  color: Colors.red.withAlpha(200),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                                ),
                                child: SongTile(
                                  title: song.title,
                                  artist: song.artist,
                                  thumbnailUrl: song.thumbnailUrl,
                                  isPlaying: player.currentSong.value?.id == song.id && player.isPlaying.value,
                                  onTap: () {
                                    player.playAll(songs, startIndex: index);
                                  },
                                  song: song,
                                  trailing: const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFallbackIcon(ColorScheme colorScheme) {
    return Container(
      width: 220,
      height: 220,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        isLikedSongs ? Icons.favorite_rounded : Icons.library_music_rounded,
        size: 64,
        color: colorScheme.primary.withAlpha(120),
      ),
    );
  }
}
