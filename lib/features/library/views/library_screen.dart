import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/shared/controllers/download_controller.dart';
import 'package:riftwave_music/shared/widgets/song_tile.dart';
import 'package:riftwave_music/routes/app_routes.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final library = Get.find<LibraryController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(() {
          if (!library.isInitialized.value) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Library',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildLikedSongsCard(context, colorScheme, library),
                      const SizedBox(height: 16),
                      _buildDownloadedSongsCard(context, colorScheme, library),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),

              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionHeader('Playlists', onAdd: () {
                    _showCreatePlaylistSheet(context, colorScheme, library);
                  }),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 16, bottom: 30),
                sliver: SliverToBoxAdapter(
                  child: _buildPlaylists(context, colorScheme, library),
                ),
              ),

              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionHeader('History', onClear: () {
                    Get.defaultDialog(
                      title: 'Clear History',
                      middleText: 'Are you sure you want to clear your entire listening history?',
                      textConfirm: 'Clear',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        library.clearHistory();
                        Get.back();
                      },
                    );
                  }),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 16, bottom: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildHistoryList(library, colorScheme),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)), 
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd, VoidCallback? onClear}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            if (onClear != null)
              TextButton(
                onPressed: onClear,
                child: const Text('Clear All'),
              ),
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_rounded),
                color: Colors.white,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLikedSongsCard(BuildContext context, ColorScheme colorScheme, LibraryController library) {
    final count = library.likedSongs.length;
    final images = library.likedSongs.map((s) => s.thumbnailUrl).where((url) => url.isNotEmpty).take(4).toList();

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.likedSongs);
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(200),
              colorScheme.primary.withAlpha(80),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Liked Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$count songs',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Wrap(
                      children: List.generate(4, (index) {
                        if (index < images.length) {
                          return SizedBox(
                            width: 50,
                            height: 50,
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.white.withAlpha(20),
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          );
                        }
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedSongsCard(BuildContext context, ColorScheme colorScheme, LibraryController library) {
    final count = library.downloadedSongs.length;
    final images = library.downloadedSongs.map((s) => s.thumbnailUrl).where((url) => url.isNotEmpty).take(4).toList();

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.downloadedSongs);
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.withAlpha(200),
              Colors.teal.withAlpha(80),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Downloaded',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$count songs',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Wrap(
                      children: List.generate(4, (index) {
                        if (index < images.length) {
                          return SizedBox(
                            width: 50,
                            height: 50,
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.white.withAlpha(20),
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          );
                        }
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylists(BuildContext context, ColorScheme colorScheme, LibraryController library) {
    if (library.playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No custom playlists yet. Tap the + icon to create one.',
          style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: library.playlists.length,
        itemBuilder: (context, index) {
          final playlist = library.playlists[index];
          return GestureDetector(
            onTap: () {
              Get.toNamed(AppRoutes.playlistDetail, arguments: playlist);
            },
            onLongPress: () {
              _showPlaylistOptionsSheet(context, colorScheme, library, playlist.id, playlist.name);
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 130,
                    width: 130,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: playlist.songCount > 0
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: const Icon(Icons.playlist_play_rounded, size: 64, color: Colors.white54), 
                          )
                        : const Icon(Icons.library_music_rounded, size: 48, color: Colors.white30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.songCount} songs',
                    style: TextStyle(color: colorScheme.onSurface.withAlpha(150), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(LibraryController library, ColorScheme colorScheme) {
    if (library.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No listening history yet.',
            style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
          ),
        ),
      );
    }

    final player = Get.find<AudioPlayerController>();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: library.history.length,
      itemBuilder: (context, index) {
        final song = library.history[index];
        return Dismissible(
          key: ValueKey('history_${song.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => library.removeFromHistory(song.id),
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
              player.playAll(library.history.toList(), startIndex: index);
              Get.toNamed(AppRoutes.player);
            },
            song: song,
          ),
        );
      },
    );
  }

  void _showCreatePlaylistSheet(BuildContext context, ColorScheme colorScheme, LibraryController library) {
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Playlist',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Playlist name',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      library.createPlaylist(nameController.text.trim());
                      Get.back();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPlaylistOptionsSheet(BuildContext context, ColorScheme colorScheme, LibraryController library, String id, String currentName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename Playlist'),
              onTap: () {
                Get.back();
                
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Playlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                library.deletePlaylist(id);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
