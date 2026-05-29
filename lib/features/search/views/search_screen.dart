import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/search/controllers/search_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/shared/widgets/song_tile.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/routes/app_routes.dart';


class SearchScreen extends GetView<RiftSearchController> {
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
              ).animate().fadeIn(duration: 500.ms),
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
                  onChanged: controller.search,
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
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
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
                  final filteredSongs = controller.searchResults.where((song) {
                    if (controller.activeTab.value == SearchTab.youtube) {
                      return song.source == MusicSource.youtube;
                    } else if (controller.activeTab.value == SearchTab.saavn) {
                      return song.source == MusicSource.saavn;
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTabButton(context, SearchTab.youtube, 'YouTube'),
                                const SizedBox(width: 8),
                                _buildTabButton(context, SearchTab.saavn, 'JioSaavn'),
                                const SizedBox(width: 8),
                                _buildTabButton(context, SearchTab.all, 'All'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredSongs.isEmpty
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
                                      'No songs found',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface.withAlpha(120),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filteredSongs.length,
                                itemBuilder: (context, index) {
                                  final song = filteredSongs[index];
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
                                    trailing: controller.activeTab.value == SearchTab.all
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
                                  ).animate().fadeIn(
                                    duration: 300.ms,
                                    delay: (index * 40).clamp(0, 300).ms,
                                  );
                                },
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
                    controller.search(cat['name'] as String);
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

  Widget _buildTabButton(BuildContext context, SearchTab tab, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final isSelected = controller.activeTab.value == tab;
      return GestureDetector(
        onTap: () => controller.setActiveTab(tab),
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
