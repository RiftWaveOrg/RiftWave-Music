import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/player/controllers/player_controller.dart';

class PlayerScreen extends GetView<PlayerController> {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withAlpha(100),
                      colorScheme.tertiary.withAlpha(60),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(30),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: colorScheme.primary.withAlpha(120),
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: 40),

              Text(
                'No Song Playing',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

              const SizedBox(height: 8),

              Text(
                'Search for music to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

              const SizedBox(height: 48),

              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: colorScheme.onSurface.withAlpha(120),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: colorScheme.onSurface,
                      size: 36,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: colorScheme.onSurface,
                      size: 36,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.repeat_rounded,
                      color: colorScheme.onSurface.withAlpha(120),
                    ),
                    onPressed: () {},
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
