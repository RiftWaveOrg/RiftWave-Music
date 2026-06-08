import os
import re

file_path = r'p:\RiftWave-Music\lib\features\home\views\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

slivers_start = content.find('slivers: [')
slivers_end = content.find('],\n          ),', slivers_start)

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
              )"""

content = content[:slivers_start] + new_slivers + content[slivers_end:]

mood_chips_pattern = r'Widget _buildMoodChips\(BuildContext context, ColorScheme colorScheme, ThemeData theme\) \{.*?return SizedBox\(.*?\);\s*\}'
new_mood_chips = '''Widget _buildMoodChips(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
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
  }'''
content = re.sub(mood_chips_pattern, new_mood_chips, content, flags=re.DOTALL)

playlists_list = '''
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
'''

content = content[:content.rfind('}')] + playlists_list + '}\\n'

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
