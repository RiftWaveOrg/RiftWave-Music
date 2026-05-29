import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/search/controllers/search_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/shared/widgets/song_tile.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/routes/app_routes.dart';
import 'package:riftwave_music/features/home/views/content_detail_screen.dart';

class SearchScreen extends GetView<MusicSearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playerController = Get.find<AudioPlayerController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Search',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller.textController,
                  onChanged: controller.updateQuery,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Songs, artists, or albums',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                    suffixIcon: Obx(() => controller.query.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: colorScheme.onSurface.withAlpha(150),
                            ),
                            onPressed: controller.clearSearch,
                          )
                        : const SizedBox.shrink()),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  );
                }

                if (controller.query.isNotEmpty) {
                  final filteredSongs = (controller.activeFilter.value == 'All' || controller.activeFilter.value == 'Songs')
                      ? controller.songResults
                      : controller.songResults.where((s) {
                          if (controller.activeFilter.value == 'YouTube') return s.source == MusicSource.youtube;
                          if (controller.activeFilter.value == 'JioSaavn') return s.source == MusicSource.saavn;
                          return false;
                        }).toList();

                  bool showEmptyState = false;
                  if (controller.activeFilter.value == 'All') {
                    showEmptyState = filteredSongs.isEmpty && controller.albumResults.isEmpty && controller.playlistResults.isEmpty;
                  } else if (controller.activeFilter.value == 'Songs' || controller.activeFilter.value == 'YouTube') {
                    showEmptyState = filteredSongs.isEmpty;
                  } else if (controller.activeFilter.value == 'Albums') {
                    showEmptyState = controller.albumResults.isEmpty;
                  } else if (controller.activeFilter.value == 'Playlists') {
                    showEmptyState = controller.playlistResults.isEmpty;
                  } else if (controller.activeFilter.value == 'JioSaavn') {
                    showEmptyState = filteredSongs.isEmpty && controller.albumResults.isEmpty && controller.playlistResults.isEmpty;
                  }

                  return Column(
                    children: [
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFilterButton(context, 'YouTube'),
                              const SizedBox(width: 8),
                              _buildFilterButton(context, 'JioSaavn'),
                              const SizedBox(width: 8),
                              _buildFilterButton(context, 'Songs'),
                              const SizedBox(width: 8),
                              _buildFilterButton(context, 'Albums'),
                              const SizedBox(width: 8),
                              _buildFilterButton(context, 'Playlists'),
                              const SizedBox(width: 8),
                              _buildFilterButton(context, 'All'),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        child: showEmptyState
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sentiment_dissatisfied_rounded,
                                      size: 64,
                                      color: colorScheme.onSurface.withAlpha(80),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No results found',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface.withAlpha(120),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: [
                                  if (controller.activeFilter.value == 'All' || controller.activeFilter.value == 'Songs' || controller.activeFilter.value == 'YouTube' || controller.activeFilter.value == 'JioSaavn') ...[
                                    if ((controller.activeFilter.value == 'All' || controller.activeFilter.value == 'JioSaavn' || controller.activeFilter.value == 'YouTube') && filteredSongs.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                                        child: Text('Top Songs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      ),
                                    ...filteredSongs.take(controller.activeFilter.value == 'All' ? 5 : filteredSongs.length).toList().asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final song = entry.value;
                                      final isCurrent = playerController.currentSong.value?.id == song.id;
                                      return SongTile(
                                        title: song.title,
                                        artist: song.artist,
                                        thumbnailUrl: song.thumbnailUrl,
                                        isPlaying: isCurrent && playerController.isPlaying.value,
                                        onTap: () {
                                          playerController.playSong(song);
                                          Get.toNamed(AppRoutes.player);
                                        },
                                        trailing: (controller.activeFilter.value == 'All' || controller.activeFilter.value == 'Songs')
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: song.source == MusicSource.saavn
                                                      ? Colors.green.withAlpha(30)
                                                      : Colors.red.withAlpha(30),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  song.source == MusicSource.saavn ? 'Saavn' : 'YouTube',
                                                  style: TextStyle(
                                                    color: song.source == MusicSource.saavn
                                                        ? Colors.greenAccent
                                                        : Colors.redAccent,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ).animate(key: ValueKey(song.id)).fadeIn(
                                        duration: 400.ms,
                                        delay: (index * 50).ms,
                                      ).scale(
                                        begin: const Offset(0.9, 0.9),
                                        end: const Offset(1, 1),
                                        duration: 400.ms,
                                        delay: (index * 50).ms,
                                      );
                                    }),
                                  ],
                                  

                                  if (controller.activeFilter.value == 'All' || controller.activeFilter.value == 'Albums' || controller.activeFilter.value == 'JioSaavn') ...[
                                    if ((controller.activeFilter.value == 'All' || controller.activeFilter.value == 'JioSaavn') && controller.albumResults.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12, top: 16),
                                        child: Text('Albums', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      ),
                                    ...controller.albumResults.take(controller.activeFilter.value == 'All' ? 5 : controller.albumResults.length).toList().asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final album = entry.value;
                                      return ListTile(
                                        onTap: () {
                                          Get.to(() => ContentDetailScreen(
                                            title: album['name'] ?? 'Album',
                                            imageUrl: album['imageUrl'] ?? '',
                                            subtitle: album['subtitle'] ?? '',
                                            type: 'Album',
                                            id: album['id'] ?? '',
                                          ));
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: album['imageUrl'] != '' 
                                              ? Image.network(album['imageUrl'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: colorScheme.surfaceContainerHighest, child: const Icon(Icons.album)))
                                              : Container(width: 50, height: 50, color: colorScheme.surfaceContainerHighest, child: const Icon(Icons.album)),
                                        ),
                                        title: Text(album['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text(album['subtitle'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ).animate(key: ValueKey('album_${album['id'] ?? index}')).fadeIn(
                                        duration: 400.ms,
                                        delay: (index * 50).ms,
                                      ).scale(
                                        begin: const Offset(0.9, 0.9),
                                        end: const Offset(1, 1),
                                        duration: 400.ms,
                                        delay: (index * 50).ms,
                                      );
                                    }),
                                  ],
                                  
                                  if (controller.activeFilter.value == 'All' || controller.activeFilter.value == 'Playlists' || controller.activeFilter.value == 'JioSaavn') ...[
                                    if ((controller.activeFilter.value == 'All' || controller.activeFilter.value == 'JioSaavn') && controller.playlistResults.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12, top: 16),
                                        child: Text('Playlists', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      ),
                                    ...controller.playlistResults.take(controller.activeFilter.value == 'All' ? 5 : controller.playlistResults.length).toList().asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final playlist = entry.value;
                                      return ListTile(
                                        onTap: () {
                                          Get.to(() => ContentDetailScreen(
                                            title: playlist['title'] ?? 'Playlist',
                                            imageUrl: playlist['imageUrl'] ?? '',
                                            subtitle: playlist['subtitle'] ?? '',
                                            type: 'Playlist',
                                            id: playlist['id'] ?? '',
                                          ));
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: playlist['imageUrl'] != '' 
                                              ? Image.network(playlist['imageUrl'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: colorScheme.surfaceContainerHighest, child: const Icon(Icons.queue_music)))
                                              : Container(width: 50, height: 50, color: colorScheme.surfaceContainerHighest, child: const Icon(Icons.queue_music)),
                                        ),
                                        title: Text(playlist['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text(playlist['subtitle'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ).animate(key: ValueKey('playlist_${playlist['id'] ?? index}')).fadeIn(
                                        duration: 400.ms,
                                        delay: (index * 50).ms,
                                      ).scale(
                                        begin: const Offset(0.9, 0.9),
                                        end: const Offset(1, 1),
                                        duration: 400.ms,
                                        delay: (index * 50).ms,
                                      );
                                    }),
                                  ],
                                  const SizedBox(height: 100),
                                ],
                              ),
                      ),
                    ],
                  );
                }

                return _buildBrowseCategories(colorScheme, theme);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseCategories(ColorScheme colorScheme, ThemeData theme) {
    final categories = [
      {'name': 'Hindi', 'icon': Icons.music_note_rounded, 'color': 0xFFE91E63},
      {'name': 'Pop', 'icon': Icons.star_rounded, 'color': 0xFF9C27B0},
      {'name': 'Rock', 'icon': Icons.electric_bolt_rounded, 'color': 0xFFFF5722},
      {'name': 'Hip Hop', 'icon': Icons.headphones_rounded, 'color': 0xFF2196F3},
      {'name': 'Electronic', 'icon': Icons.equalizer_rounded, 'color': 0xFF00BCD4},
      {'name': 'Lo-Fi', 'icon': Icons.nightlight_rounded, 'color': 0xFF607D8B},
      {'name': 'Bollywood', 'icon': Icons.movie_rounded, 'color': 0xFFFF9800},
      {'name': 'Devotional', 'icon': Icons.self_improvement_rounded, 'color': 0xFF4CAF50},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final color = Color(cat['color'] as int);
                return InkWell(
                  onTap: () {
                    controller.updateQuery(cat['name'] as String);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withAlpha(180),
                          color.withAlpha(80),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(
                            cat['icon'] as IconData,
                            color: Colors.white.withAlpha(120),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  duration: 400.ms,
                  delay: (index * 80).ms,
                ).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  delay: (index * 80).ms,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final isSelected = controller.activeFilter.value == label;
      return GestureDetector(
        onTap: () => controller.setActiveFilter(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(color: colorScheme.onSurface.withAlpha(40)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withAlpha(150),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }
}
