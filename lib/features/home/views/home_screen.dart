import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/features/home/controllers/home_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/features/home/views/content_detail_screen.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: _buildMoodChips(context, colorScheme, theme),
                ),
              ),
              Obx(() {
                final library = Get.find<LibraryController>();
                // Force Obx registration
                library.history.length;
                
                if (library.history.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(theme, 'Recently Played'),
                        const SizedBox(height: 12),
                        _buildRecentlyPlayedGrid(context, colorScheme, theme, library.history),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.dailyMix.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Your Daily Mix'),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.dailyMix.isEmpty) {
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
                          child: _buildSectionHeader(theme, 'Your Daily Mix'),
                        ),
                        const SizedBox(height: 12),
                        _buildDailyMixList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.regionalCharts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Trending in Region'),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.regionalCharts.isEmpty) {
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
                          child: _buildSectionHeader(theme, 'Trending in Region'),
                        ),
                        const SizedBox(height: 12),
                        _buildRegionalChartsList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.trendingSongs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Trending Now'),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
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
                          child: _buildSectionHeader(theme, 'Trending Now'),
                        ),
                        const SizedBox(height: 12),
                        _buildTrendingList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.popularPlaylists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Popular Playlists'),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
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
                          child: _buildSectionHeader(theme, 'Popular Playlists'),
                        ),
                        const SizedBox(height: 12),
                        _buildPopularPlaylistsList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.youtubePlaylists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSectionHeader(theme, 'YouTube Curated Playlists'),
                          ),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.youtubePlaylists.isEmpty) {
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
                          child: _buildSectionHeader(theme, 'YouTube Curated Playlists'),
                        ),
                        const SizedBox(height: 12),
                        _buildYouTubePlaylistsList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.youtubeTrending.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Trending on YouTube'),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.youtubeTrending.isEmpty) {
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
                          child: _buildSectionHeader(theme, 'Trending on YouTube'),
                        ),
                        const SizedBox(height: 12),
                        _buildYtTrendingList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.newReleases.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'New Releases'),
                          const SizedBox(height: 12),
                          _buildShimmerHorizontalList(colorScheme),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.newReleases.isEmpty) {
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
                          child: _buildSectionHeader(theme, 'New Releases'),
                        ),
                        const SizedBox(height: 12),
                        _buildNewReleasesList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                if (controller.isLoading.value && controller.regionalArtists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Regional Artists'),
                          const SizedBox(height: 12),
                          _buildShimmerArtistList(colorScheme),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.regionalArtists.isEmpty) {
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
                          child: _buildSectionHeader(theme, 'Regional Artists'),
                        ),
                        const SizedBox(height: 12),
                        _buildRegionalArtistsList(context, colorScheme, theme),
                      ],
                    ),
                  ),
                );
              }),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildMoodChips(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final moods = [
      {'label': 'Chill 😌', 'query': 'chill lofi acoustic chillout'},
      {'label': 'Hype ⚡', 'query': 'hype gym workout party dance'},
      {'label': 'Focus 🎯', 'query': 'focus deep study concentration ambient'},
      {'label': 'Sleep 🌙', 'query': 'sleep ambient rain relaxing soundscape'},
      {'label': 'Happy 😊', 'query': 'happy upbeat energetic feel good'},
      {'label': 'Sad 💙', 'query': 'sad acoustic emotional heartfelt ballad'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(
                mood['label']!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              onPressed: () {
                Get.to(() => ContentDetailScreen(
                  title: mood['label']!,
                  imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&q=80',
                  subtitle: 'Curated Mood Tracks',
                  type: 'Mood',
                  id: mood['query']!,
                ));
              },
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Widget _buildRecentlyPlayedGrid(BuildContext context, ColorScheme colorScheme, ThemeData theme, List<SongModel> historyList) {
    final songs = historyList.take(6).toList();
    final playerController = Get.find<AudioPlayerController>();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return GestureDetector(
          onTap: () {
            playerController.playSong(song);
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(40),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: song.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.music_note_rounded, color: colorScheme.primary),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.music_note_rounded, color: colorScheme.primary),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.music_note_rounded, color: colorScheme.primary),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                const SizedBox(width: 8),
              ],
            ),
          ),
        ).animate().fadeIn(
          duration: 400.ms,
          delay: (index * 80).ms,
        ).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: (index * 80).ms,
        );
      },
    );
  }

  Widget _buildDailyMixList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final playerController = Get.find<AudioPlayerController>();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.dailyMix.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = controller.dailyMix[index];
          return GestureDetector(
            onTap: () {
              playerController.playAll(controller.dailyMix, startIndex: index);
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
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
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildRegionalChartsList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final playerController = Get.find<AudioPlayerController>();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.regionalCharts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = controller.regionalCharts[index];
          return GestureDetector(
            onTap: () {
              playerController.playAll(controller.regionalCharts, startIndex: index);
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
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
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final playerController = Get.find<AudioPlayerController>();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.trendingSongs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = controller.trendingSongs[index];
          return GestureDetector(
            onTap: () {
              playerController.playAll(controller.trendingSongs, startIndex: index);
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
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
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildPopularPlaylistsList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.popularPlaylists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final playlist = controller.popularPlaylists[index];
          return GestureDetector(
            onTap: () {
              Get.to(() => ContentDetailScreen(
                title: playlist['title'] ?? '',
                imageUrl: playlist['thumbnailUrl'] ?? '',
                subtitle: playlist['subtitle'] ?? '',
                type: 'Playlist',
                id: playlist['id'] ?? '',
              ));
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (playlist['thumbnailUrl'] as String).isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: playlist['thumbnailUrl'] as String,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.queue_music_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.queue_music_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.queue_music_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist['title'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    playlist['subtitle'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildYouTubePlaylistsList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.youtubePlaylists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final playlist = controller.youtubePlaylists[index];
          return GestureDetector(
            onTap: () {
              Get.to(() => ContentDetailScreen(
                title: playlist['title'] ?? '',
                imageUrl: playlist['thumbnailUrl'] ?? '',
                subtitle: playlist['subtitle'] ?? '',
                type: 'YoutubePlaylist',
                id: playlist['id'] ?? '',
              ));
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (playlist['thumbnailUrl'] as String).isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: playlist['thumbnailUrl'] as String,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist['title'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    playlist['subtitle'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildYtTrendingList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final playerController = Get.find<AudioPlayerController>();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.youtubeTrending.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = controller.youtubeTrending[index];
          return GestureDetector(
            onTap: () {
              playerController.playAll(controller.youtubeTrending, startIndex: index);
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
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
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildNewReleasesList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.newReleases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final album = controller.newReleases[index];
          return GestureDetector(
            onTap: () {
              Get.to(() => ContentDetailScreen(
                title: album['name'] ?? '',
                imageUrl: album['thumbnailUrl'] ?? '',
                subtitle: album['artist'] ?? '',
                type: 'Album',
                id: album['name'] ?? '',
              ));
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (album['thumbnailUrl'] as String).isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: album['thumbnailUrl'] as String,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.album_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.album_rounded,
                                  color: colorScheme.primary.withAlpha(120),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.album_rounded,
                                color: colorScheme.primary.withAlpha(120),
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album['name'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album['artist'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 80).ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: (index * 80).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildRegionalArtistsList(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.regionalArtists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final artist = controller.regionalArtists[index];
          return GestureDetector(
            onTap: () {
              Get.to(() => ContentDetailScreen(
                title: artist['name'] ?? '',
                imageUrl: artist['imageUrl'] ?? '',
                subtitle: 'Top Songs',
                type: 'Artist',
                id: artist['id'] ?? '',
              ));
            },
            child: SizedBox(
              width: 90,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(40),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: (artist['imageUrl'] as String).isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: artist['imageUrl'] as String,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.person_rounded, color: colorScheme.primary),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.person_rounded, color: colorScheme.primary),
                              ),
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.person_rounded, color: colorScheme.primary),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artist['name'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildShimmerHorizontalList(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHighest.withAlpha(80),
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerArtistList(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHighest.withAlpha(80),
      child: SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 18),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 90,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
