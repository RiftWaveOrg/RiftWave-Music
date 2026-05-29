import 'dart:async';
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
    final ScrollController mainScrollController = ScrollController();

    final RxDouble scrollPercent = 0.0.obs;
    mainScrollController.addListener(() {
      if (mainScrollController.hasClients) {
        final pixels = mainScrollController.position.pixels;
        scrollPercent.value = (pixels / 140.0).clamp(0.0, 1.0);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final percent = scrollPercent.value;
          final song = audioController.currentSong.value;
          final songTitle = song?.title ?? '';
          final songArtist = song?.artist ?? '';

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: percent < 0.5
                ? Column(
                    key: const ValueKey('now_playing'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NOW PLAYING',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          color: colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('song_details'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200,
                        child: MarqueeText(
                          text: songTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        songArtist,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(150),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          );
        }),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: mainScrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Obx(() {
          final song = audioController.currentSong.value;

          final double screenHeight = MediaQuery.of(context).size.height;
          final double appBarHeight = AppBar().preferredSize.height;
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double navigationBarHeight = MediaQuery.of(context).padding.bottom;
          final double playerSectionHeight = screenHeight - appBarHeight - statusBarHeight - navigationBarHeight - 16;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                constraints: BoxConstraints(minHeight: playerSectionHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    Center(
                      child: Container(
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
                      ),
                    ).animate().fadeIn(duration: 700.ms).scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1),
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        ),

                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: MarqueeText(
                            text: song?.title ?? 'No Song Playing',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

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
                      ],
                    ),

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
                                width: 64,
                                height: 64,
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
                                      size: 32,
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(130),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.onSurface.withAlpha(15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'LYRICS',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: colorScheme.onSurface.withAlpha(25)),
                    const SizedBox(height: 12),
                    _buildLyricsView(colorScheme, theme, audioController),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(130),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.onSurface.withAlpha(15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ARTIST BIO',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: colorScheme.onSurface.withAlpha(25)),
                    const SizedBox(height: 12),
                    _buildBioView(colorScheme, theme),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(130),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.onSurface.withAlpha(15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'RECOMMENDED TRACKS',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: colorScheme.onSurface.withAlpha(25)),
                    const SizedBox(height: 12),
                    _buildSimilarView(colorScheme, theme, audioController),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLyricsView(
    ColorScheme colorScheme,
    ThemeData theme,
    AudioPlayerController audioController,
  ) {
    if (controller.isLoadingLyrics.value) {
      return _buildLoadingPlaceholder(colorScheme);
    }

    final double containerHeight = MediaQuery.of(Get.context!).size.height * 0.40;

    if (controller.parsedLyrics.isNotEmpty) {
      int lastActiveIndex = -1;

      return Obx(() {
        final currentPos = audioController.currentPosition.value;

        int activeIndex = -1;
        for (int i = 0; i < controller.parsedLyrics.length; i++) {
          if (controller.parsedLyrics[i].time <= currentPos) {
            activeIndex = i;
          } else {
            break;
          }
        }

        if (activeIndex != -1 && activeIndex != lastActiveIndex && controller.lyricsScrollController.hasClients) {
          lastActiveIndex = activeIndex;
          final targetOffset = (activeIndex * 52.0) - (containerHeight / 2.0) + 26.0;
          controller.lyricsScrollController.animateTo(
            targetOffset.clamp(0.0, controller.lyricsScrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        return SizedBox(
          height: containerHeight,
          child: ListView.builder(
            controller: controller.lyricsScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: controller.parsedLyrics.length,
            itemBuilder: (context, index) {
              final line = controller.parsedLyrics[index];
              final isActive = index == activeIndex;

              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurface.withAlpha(isActive ? 255 : 120),
                  fontSize: isActive ? 20 : 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(line.text),
                ),
              );
            },
          ),
        );
      });
    }

    if (controller.plainLyrics.value.isNotEmpty) {
      return SizedBox(
        height: containerHeight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Text(
              controller.plainLyrics.value,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                letterSpacing: 0.5,
                color: colorScheme.onSurface.withAlpha(200),
              ),
            ),
          ),
        ),
      );
    }

    return _buildMessagePlaceholder('No lyrics found.', colorScheme, theme);
  }

  Widget _buildBioView(ColorScheme colorScheme, ThemeData theme) {
    if (controller.isLoadingBio.value) {
      return _buildLoadingPlaceholder(colorScheme);
    }

    if (controller.artistBio.value.isEmpty) {
      return _buildMessagePlaceholder('No biography available.', colorScheme, theme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        controller.artistBio.value,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: colorScheme.onSurface.withAlpha(190),
        ),
      ),
    );
  }

  Widget _buildSimilarView(
    ColorScheme colorScheme,
    ThemeData theme,
    AudioPlayerController audioController,
  ) {
    if (controller.isLoadingSimilar.value) {
      return _buildLoadingPlaceholder(colorScheme);
    }

    if (controller.similarSongs.isEmpty) {
      return _buildMessagePlaceholder('No recommendations found.', colorScheme, theme);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: controller.similarSongs.length,
      itemBuilder: (context, index) {
        final song = controller.similarSongs[index];

        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.primary.withAlpha(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: song.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.music_note_rounded),
                  )
                : const Icon(Icons.music_note_rounded),
          ),
          title: Text(
            song.title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            style: TextStyle(color: colorScheme.onSurface.withAlpha(120), fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(Icons.play_circle_outline_rounded, color: colorScheme.primary),
            onPressed: () => audioController.playSong(song),
          ),
          onTap: () => audioController.playSong(song),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }

  Widget _buildMessagePlaceholder(String message, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withAlpha(120),
        ),
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

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({super.key, required this.text, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final currentScroll = _scrollController.position.pixels;
      double nextScroll = currentScroll + 1.0;

      if (nextScroll >= maxScroll) {
        nextScroll = 0.0;
        _scrollController.jumpTo(0.0);
      } else {
        _scrollController.jumpTo(nextScroll);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
