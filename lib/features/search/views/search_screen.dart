import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/search/controllers/search_controller.dart';

class SearchScreen extends GetView<RiftSearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: colorScheme.primary.withAlpha(80),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search will be available soon',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                      ],
                    ),
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
                return Container(
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
}
