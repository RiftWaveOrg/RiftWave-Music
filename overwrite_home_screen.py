content = """import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/features/home/controllers/home_controller.dart';
import 'package:riftwave_music/features/home/views/content_detail_screen.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.greeting.value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(
                      begin: -0.1,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What do you want to listen to?',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                    ).animate().fadeIn(
                      duration: 600.ms,
                      delay: 200.ms,
                    ),
                  ],
                )),
              ),
            ),
            // Mood Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildMoodChips(context, colorScheme, theme),
              ),
            ),
            // Quick Picks
            Obx(() {
              if (controller.isLoading.value && controller.quickPicks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(theme, 'Quick picks'),
                        const SizedBox(height: 12),
                        _buildShimmerHorizontalList(colorScheme),
                      ],
                    ),
                  ),
                );
              }
              if (controller.quickPicks.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Quick picks' : '${controller.currentMood.value} picks')),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickPicksList(context, colorScheme, theme),
                    ],
                  ),
                ),
              );
            }),
            // Listen again
            Obx(() {
              final library = Get.find<LibraryController>();
              if (library.history.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionHeader(theme, 'Listen again'),
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalSongList(context, colorScheme, theme, library.history.take(15).toList()),
                    ],
                  ),
                ),
              );
            }),
            // Playlists
            Obx(() {
              if (controller.isLoading.value && controller.popularPlaylists.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.popularPlaylists.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Popular Playlists' : '${controller.currentMood.value} Playlists')),
                      ),
                      const SizedBox(height: 12),
                      _buildPlaylistsList(context, colorScheme, theme),
                    ],
                  ),
                ),
              );
            }),
            // Trending on YouTube
            Obx(() {
              if (controller.isLoading.value && controller.trendingSongs.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.trendingSongs.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Trending on YouTube' : 'Trending ${controller.currentMood.value}')),
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalSongList(context, colorScheme, theme, controller.trendingSongs),
                    ],
                  ),
                ),
              );
            }),
            // Recommended music videos
            Obx(() {
              if (controller.isLoading.value && controller.recommendedVideos.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.recommendedVideos.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Recommended music videos' : '${controller.currentMood.value} music videos')),
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendedVideosList(context, colorScheme, theme),
                    ],
                  ),
                ),
              );
            }),
            // Mixed for you
            Obx(() {
              if (controller.isLoading.value && controller.mixedForYou.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.mixedForYou.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Mixed for you' : '${controller.currentMood.value} mix')),
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalSongList(context, colorScheme, theme, controller.mixedForYou),
                    ],
                  ),
                ),
              );
            }),
            // Similar to [Artist]
            Obx(() {
              if (controller.isLoading.value && controller.similarToArtistSongs.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.similarToArtistSongs.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionHeader(theme, 'Similar to ${controller.similarArtistName.value}'),
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalSongList(context, colorScheme, theme, controller.similarToArtistSongs),
                    ],
                  ),
                ),
              );
            }),
            // Forgotten favorites
            Obx(() {
              if (controller.isLoading.value && controller.forgottenFavorites.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.forgottenFavorites.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Forgotten favorites' : '${controller.currentMood.value} favorites')),
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalSongList(context, colorScheme, theme, controller.forgottenFavorites),
                    ],
                  ),
                ),
              );
            }),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildShimmerHorizontalList(ColorScheme colorScheme) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 140, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 8),
                Container(width: 100, height: 16, color: colorScheme.surfaceContainerHighest),
                const SizedBox(height: 4),
                Container(width: 80, height: 12, color: colorScheme.surfaceContainerHighest),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodChips(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final moods = [
      {'label': 'All', 'icon': Icons.all_inclusive_rounded},
      {'label': 'Relax', 'icon': Icons.spa_rounded},
      {'label': 'Workout', 'icon': Icons.fitness_center_rounded},
      {'label': 'Focus', 'icon': Icons.headphones_rounded},
      {'label': 'Party', 'icon': Icons.celebration_rounded},
      {'label': 'Romance', 'icon': Icons.favorite_rounded},
      {'label': 'Sad', 'icon': Icons.water_drop_rounded},
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mood = moods[index];
          final label = mood['label'] as String;
          return Obx(() {
            final isSelected = controller.currentMood.value == label;
            return ActionChip(
              label: Text(label),
              avatar: Icon(mood['icon'] as IconData, size: 18, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
              backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withAlpha(150),
              side: BorderSide(color: isSelected ? Colors.transparent : colorScheme.outlineVariant.withAlpha(100)),
              labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              onPressed: () {
                controller.changeMood(label);
              },
            ).animate().fadeIn(
              duration: 300.ms,
              delay: (index * 50).ms,
            ).slideX(
              begin: 0.2,
              end: 0,
              duration: 300.ms,
              delay: (index * 50).ms,
              curve: Curves.easeOut,
            );
          });
        },
      ),
    );
  }

  Widget _buildPlaylistsList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.popularPlaylists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final pl = controller.popularPlaylists[index];
          return GestureDetector(
            onTap: () {
              Get.to(() => ContentDetailScreen(
                title: pl['title'] ?? '',
                imageUrl: pl['thumbnailUrl'] ?? '',
                subtitle: pl['subtitle'] ?? 'YouTube Playlist',
                type: 'Playlist',
                id: pl['id'] ?? '',
              ));
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (pl['thumbnailUrl'] as String).isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: pl['thumbnailUrl'] as String,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                            errorWidget: (context, url, error) => Container(color: colorScheme.surfaceContainerHighest),
                          )
                        : Container(width: 140, height: 140, color: colorScheme.surfaceContainerHighest),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pl['title'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pl['subtitle'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(150)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms);
        },
      ),
    );
  }

  Widget _buildHorizontalSongList(BuildContext context, ColorScheme colorScheme, ThemeData theme, List<SongModel> songs) {
    final playerController = Get.find<AudioPlayerController>();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () {
              playerController.playAll(songs, startIndex: index);
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.music_note_rounded, color: colorScheme.primary.withAlpha(120), size: 40),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.music_note_rounded, color: colorScheme.primary.withAlpha(120), size: 40),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.music_note_rounded, color: colorScheme.primary.withAlpha(120), size: 40),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms);
        },
      ),
    );
  }

  Widget _buildQuickPicksList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final playerController = Get.find<AudioPlayerController>();
    final chunks = <List<SongModel>>[];
    for (var i = 0; i < controller.quickPicks.length; i += 4) {
      chunks.add(controller.quickPicks.sublist(i, i + 4 > controller.quickPicks.length ? controller.quickPicks.length : i + 4));
    }

    return SizedBox(
      height: 280, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chunks.length,
        itemBuilder: (context, index) {
          final chunk = chunks[index];
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              children: chunk.map((song) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 16),
                  child: GestureDetector(
                    onTap: () {
                      playerController.playAll(controller.quickPicks, startIndex: controller.quickPicks.indexOf(song));
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: song.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.thumbnailUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : Container(width: 56, height: 56, color: colorScheme.surfaceContainerHighest),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(150))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withAlpha(150)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedVideosList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final playerController = Get.find<AudioPlayerController>();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.recommendedVideos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = controller.recommendedVideos[index];
          return GestureDetector(
            onTap: () {
              playerController.playAll(controller.recommendedVideos, startIndex: index);
            },
            child: SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 260,
                            height: 146,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              width: 260, height: 146,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              width: 260, height: 146,
                            ),
                          )
                        : Container(
                            width: 260,
                            height: 146,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.person, size: 20, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(150),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms);
        },
      ),
    );
  }
}
"""

with open(r'p:\RiftWave-Music\lib\features\home\views\home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
