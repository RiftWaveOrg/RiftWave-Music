import re

f = open(r'p:\RiftWave-Music\lib\features\home\views\home_screen.dart', 'r', encoding='utf-8')
c = f.read()
f.close()

# 1. Remove newReleases section completely
c = re.sub(r'// New Releases.*?_buildNewReleasesList\(context, colorScheme, theme\),.*?\]\),\s*\),\s*\);\s*}\),', '', c, flags=re.DOTALL)

# 2. Change Regional Artists section to Popular Playlists
c = re.sub(
r'// Regional Artists\s+Obx\(\(\) \{\s+if \(controller\.regionalArtists\.isEmpty\).*?_buildRegionalArtistsList\(context, colorScheme, theme\),.*?\]\),\s*\),\s*\);\s*}\),',
'''              // Popular Playlists
              Obx(() {
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
              }),''', c, flags=re.DOTALL)

# 3. Add dynamic headers using Obx to existing sections
c = c.replace("_buildSectionHeader(theme, 'Trending on YouTube')", "Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Trending on YouTube' : 'Trending ${controller.currentMood.value} on YouTube'))")
c = c.replace("_buildSectionHeader(theme, 'Quick picks')", "Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Quick picks' : '${controller.currentMood.value} picks'))")
c = c.replace("_buildSectionHeader(theme, 'Recommended music videos')", "Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Recommended music videos' : 'Recommended ${controller.currentMood.value} videos'))")
c = c.replace("_buildSectionHeader(theme, 'Mixed for you')", "Obx(() => _buildSectionHeader(theme, controller.currentMood.value == 'All' ? 'Mixed for you' : '${controller.currentMood.value} mix'))")

# 4. Replace _buildMoodChips to add 'All' and reactive styling
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
c = re.sub(mood_chips_pattern, new_mood_chips, c, flags=re.DOTALL)

# 5. Remove _buildNewReleasesList and _buildRegionalArtistsList
c = re.sub(r'Widget _buildNewReleasesList\(.*?return SizedBox\([^;]*?\);\s*\}', '', c, flags=re.DOTALL)
c = re.sub(r'Widget _buildRegionalArtistsList\(.*?return SizedBox\([^;]*?\);\s*\}', '', c, flags=re.DOTALL)

# 6. Add _buildPlaylistsList at the end
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
c = c[:c.rfind('}')] + playlists_list + '}\n'

with open(r'p:\RiftWave-Music\lib\features\home\views\home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)
