import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';

class PlaylistSelectorSheet extends StatelessWidget {
  final SongModel song;

  const PlaylistSelectorSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final library = Get.find<LibraryController>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add to Playlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Obx(() {
            if (library.playlists.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  'No custom playlists found.\nCreate one in the Library tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
                ),
              );
            }

            return Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: library.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = library.playlists[index];
                  final isAdded = playlist.songIds.contains(song.id);

                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.queue_music_rounded, color: Colors.white54),
                    ),
                    title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${playlist.songCount} songs'),
                    trailing: isAdded
                        ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                        : const Icon(Icons.radio_button_unchecked_rounded),
                    onTap: () {
                      if (isAdded) {
                        library.removeSongFromPlaylist(playlist.id, song.id);
                      } else {
                        library.addSongToPlaylist(playlist.id, song);
                      }
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
