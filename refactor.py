import re
import os

file_path = r"p:\RiftWave-Music\lib\features\home\views\home_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# We need to replace the slivers list inside CustomScrollView and add the new helper methods.
# The new helpers are _buildQuickPicksList, _buildRecommendedVideosList, and the refactored _buildMoodChips grid.

# Let's replace the entire slivers array.
slivers_start = content.find("slivers: [")
slivers_end = content.find("],\n          ),", slivers_start)

new_slivers = """slivers: [
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
                          _buildShimmerHorizontalList(colorScheme), // Can reuse shimmer
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
                          child: _buildSectionHeader(theme, 'Quick picks'),
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
                          child: _buildSectionHeader(theme, 'Recommended music videos'),
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
                if (controller.isLoading.value && controller.dailyMix.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
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
                          child: _buildSectionHeader(theme, 'Mixed for you'),
                        ),
                        const SizedBox(height: 12),
                        _buildHorizontalSongList(context, colorScheme, theme, controller.dailyMix),
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
                          child: _buildSectionHeader(theme, 'Forgotten favorites'),
                        ),
                        const SizedBox(height: 12),
                        _buildHorizontalSongList(context, colorScheme, theme, controller.forgottenFavorites),
                      ],
                    ),
                  ),
                );
              }),
              // New Releases
              Obx(() {
                if (controller.isLoading.value && controller.newReleases.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
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
              // Top songs
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
                          child: _buildSectionHeader(theme, 'Top songs'),
                        ),
                        const SizedBox(height: 12),
                        _buildHorizontalSongList(context, colorScheme, theme, controller.trendingSongs),
                      ],
                    ),
                  ),
                );
              }),
              // Regional Artists
              Obx(() {
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
              // Moods and genres (Grid wrap at bottom)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(theme, 'Moods and genres'),
                      const SizedBox(height: 16),
                      _buildMoodsAndGenresGrid(context, colorScheme, theme),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              )"""

new_content = content[:slivers_start] + new_slivers + content[slivers_end:]

helpers_to_add = """

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
                    borderRadius: BorderRadius.circular(8), // SimpMusic uses 8px border radius mostly
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
                            height: 146, // 16:9 aspect ratio
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

  Widget _buildMoodsAndGenresGrid(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final moods = [
      {'label': 'Chill', 'color': 0xFF2A5948},
      {'label': 'Romance', 'color': 0xFF7D323E},
      {'label': 'Sad', 'color': 0xFF314364},
      {'label': 'Feel good', 'color': 0xFFB46E2E},
      {'label': 'Workout', 'color': 0xFF6D2F6B},
      {'label': 'Party', 'color': 0xFF254B78},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: moods.map((mood) {
        return GestureDetector(
          onTap: () {
            Get.to(() => ContentDetailScreen(
              title: mood['label'] as String,
              imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&q=80',
              subtitle: 'Curated Mood Tracks',
              type: 'Mood',
              id: '${mood['label']} songs',
            ));
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2, // 2 columns
            height: 48,
            decoration: BoxDecoration(
              color: Color(mood['color'] as int).withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              mood['label'] as String,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
"""

new_content = new_content[:new_content.rfind("}")] + helpers_to_add + "}\n"

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)
