import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/core/audio/repeat_mode.dart';
import 'package:riftwave_music/core/utils/duration_formatter.dart';
import 'package:riftwave_music/features/player/controllers/player_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

class PlayerScreen extends GetView<PlayerController> {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final audioController = Get.find<AudioPlayerController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              'NOW PLAYING',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {

            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final song = audioController.currentSong.value;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 1),

                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(40),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: song != null && song.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _artPlaceholder(colorScheme),
                          errorWidget: (_, __, ___) =>
                              _artPlaceholder(colorScheme),
                        )
                      : _artPlaceholder(colorScheme),
                ).animate().fadeIn(duration: 700.ms).scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),

                const Spacer(flex: 1),

                Text(
                  song?.title ?? 'No Song Playing',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                const SizedBox(height: 6),

                Text(
                  song?.artist ?? 'Search for music to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                const SizedBox(height: 32),

                Obx(() {
                  final pos = audioController.currentPosition.value;
                  final dur = audioController.totalDuration.value;
                  final maxMs = dur.inMilliseconds.toDouble();

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: maxMs > 0
                              ? pos.inMilliseconds
                                  .toDouble()
                                  .clamp(0, maxMs)
                              : 0,
                          max: maxMs > 0 ? maxMs : 1,
                          onChanged: (value) {
                            audioController.seekTo(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DurationFormatter.format(pos),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                            Text(
                              DurationFormatter.format(dur),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Obx(() => IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: audioController.shuffleMode.value
                                ? colorScheme.primary
                                : colorScheme.onSurface.withAlpha(120),
                          ),
                          onPressed: audioController.toggleShuffle,
                        )),

                    const SizedBox(width: 12),

                    IconButton(
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: colorScheme.onSurface,
                        size: 36,
                      ),
                      onPressed: audioController.skipToPrevious,
                    ),

                    const SizedBox(width: 12),

                    Obx(() => GestureDetector(
                          onTap: audioController.togglePlayPause,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withAlpha(80),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  audioController.isPlaying.value
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(audioController.isPlaying.value),
                                  color: colorScheme.onPrimary,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        )),

                    const SizedBox(width: 12),

                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: colorScheme.onSurface,
                        size: 36,
                      ),
                      onPressed: audioController.skipToNext,
                    ),

                    const SizedBox(width: 12),

                    Obx(() {
                      final mode = audioController.repeatMode.value;
                      final isActive = mode != RiftWaveRepeatMode.off;
                      return IconButton(
                        icon: Icon(
                          mode == RiftWaveRepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurface.withAlpha(120),
                        ),
                        onPressed: audioController.cycleRepeatMode,
                      );
                    }),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                const Spacer(flex: 2),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _artPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha(100),
            colorScheme.tertiary.withAlpha(60),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: colorScheme.primary.withAlpha(120),
        ),
      ),
    );
  }
}
