import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/home/controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionHeader(theme, 'Recently Played'),
                    const SizedBox(height: 12),
                    _buildPlaceholderGrid(colorScheme),
                    const SizedBox(height: 28),
                    _buildSectionHeader(theme, 'Trending Now'),
                    const SizedBox(height: 12),
                    _buildPlaceholderHorizontalList(colorScheme),
                    const SizedBox(height: 28),
                    _buildSectionHeader(theme, 'Made for You'),
                    const SizedBox(height: 12),
                    _buildPlaceholderHorizontalList(colorScheme),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildPlaceholderGrid(ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(40),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Playlist ${index + 1}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(180),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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

  Widget _buildPlaceholderHorizontalList(ColorScheme colorScheme) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withAlpha(50),
                        colorScheme.tertiary.withAlpha(30),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.album_rounded,
                      color: colorScheme.primary.withAlpha(120),
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Album ${index + 1}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: 400.ms,
            delay: (index * 100).ms,
          ).slideX(
            begin: 0.2,
            end: 0,
            duration: 400.ms,
            delay: (index * 100).ms,
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }
}
