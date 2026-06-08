import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/shared/widgets/mini_player.dart';

class ContentDetailScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String subtitle;
  final String type;
  final String id;

  const ContentDetailScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.type,
    required this.id,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final List<SongModel> _songs = [];
  bool _isLoading = true;
  String _biography = '';
  final List<SongModel> _suggestions = [];
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final saavn = Get.find<SaavnApi>();
      final ytApi = Get.find<YouTubeApi>();

      if (widget.type == 'Playlist') {
        final songs = await saavn.getPlaylistSongs(widget.id);
        if (mounted) {
          setState(() {
            _songs.addAll(songs);
            _isLoading = false;
          });
        }
      } else if (widget.type == 'YoutubePlaylist') {
        final songs = await ytApi.getPlaylistSongs(widget.id);
        if (mounted) {
          setState(() {
            _songs.addAll(songs);
            _isLoading = false;
          });
        }
      } else if (widget.type == 'Album') {
        final songs = await saavn.searchSongs(widget.id);
        if (mounted) {
          setState(() {
            _songs.addAll(songs);
            _isLoading = false;
          });
        }
      } else if (widget.type == 'Mood') {
        final songs = await saavn.searchSongs(widget.id);
        if (mounted) {
          setState(() {
            _songs.addAll(songs);
            _isLoading = false;
          });
        }
      } else if (widget.type == 'Artist') {
        final details = await saavn.getArtistDetails(widget.id);
        if (mounted) {
          setState(() {
            _biography = details['biography'] as String? ?? '';
            final artistSongs = details['songs'] as List<SongModel>?;
            if (artistSongs != null) {
              _songs.addAll(artistSongs);
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('ContentDetailScreen: Error loading tracks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSuggestions = true;
      _suggestions.clear();
    });

    try {
      final saavn = Get.find<SaavnApi>();
      final yt = Get.find<YouTubeApi>();

      if (_songs.isNotEmpty) {
        final firstSong = _songs.first;
        final primaryArtist = _getPrimaryArtist(firstSong.artist);

        final artistId = await saavn.searchArtist(primaryArtist);
        if (artistId != null) {
          final songs = await saavn.getArtistSongs(artistId);
          final filtered = songs
              .where(
                (s) => s.title.toLowerCase() != firstSong.title.toLowerCase(),
              )
              .toList();
          if (filtered.isNotEmpty) {
            if (mounted) {
              setState(() {
                _suggestions.addAll(filtered.take(10));
                _isLoadingSuggestions = false;
              });
            }
            return;
          }
        }

        final searchResults = await saavn.searchSongs(primaryArtist);
        final filteredSearch = searchResults
            .where(
              (s) => s.title.toLowerCase() != firstSong.title.toLowerCase(),
            )
            .toList();
        if (filteredSearch.isNotEmpty) {
          if (mounted) {
            setState(() {
              _suggestions.addAll(filteredSearch.take(10));
              _isLoadingSuggestions = false;
            });
          }
          return;
        }

        final ytResults = await yt.search('$primaryArtist songs');
        final filteredYt = ytResults
            .where(
              (s) => s.title.toLowerCase() != firstSong.title.toLowerCase(),
            )
            .toList();
        if (filteredYt.isNotEmpty) {
          if (mounted) {
            setState(() {
              _suggestions.addAll(filteredYt.take(10));
              _isLoadingSuggestions = false;
            });
          }
          return;
        }
      } else {
        final searchResults = await saavn.searchSongs(widget.title);
        if (searchResults.isNotEmpty) {
          if (mounted) {
            setState(() {
              _suggestions.addAll(searchResults.take(10));
              _isLoadingSuggestions = false;
            });
          }
          return;
        }

        final ytResults = await yt.search('${widget.title} songs');
        if (ytResults.isNotEmpty) {
          if (mounted) {
            setState(() {
              _suggestions.addAll(ytResults.take(10));
              _isLoadingSuggestions = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('ContentDetailScreen: Error loading suggestions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  String _getPrimaryArtist(String artist) {
    if (artist.isEmpty) return '';
    String cleaned = artist;
    cleaned = cleaned.replaceAll(
      RegExp(r'\s*-\s*Topic$', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s*VEVO$', caseSensitive: false), '');
    final dividers = [
      RegExp(r'\bfeat\.?\b', caseSensitive: false),
      RegExp(r'\bft\.?\b', caseSensitive: false),
      '&',
      ',',
      'and',
      'And',
    ];
    for (final divider in dividers) {
      final parts = cleaned.split(divider);
      if (parts.isNotEmpty) {
        cleaned = parts[0];
      }
    }
    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      bottomNavigationBar: const SafeArea(
        top: false,
        child: MiniPlayer(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const SizedBox(),
                    ),
                  if (widget.imageUrl.isNotEmpty)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(color: colorScheme.surface.withAlpha(180)),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withAlpha(100),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: colorScheme.shadow.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.imageUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: widget.imageUrl, fit: BoxFit.cover)
                                : Container(color: colorScheme.surfaceContainerHighest, child: Icon(widget.type == 'Artist' ? Icons.person_rounded : Icons.music_note_rounded, size: 64, color: colorScheme.primary.withAlpha(120))),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text(widget.subtitle, style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onSurface.withAlpha(180), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_isLoading ? 'Loading...' : '${_songs.length} tracks', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (_songs.isEmpty && _suggestions.isEmpty) ? null : () {
                            Get.find<AudioPlayerController>().playAll(_songs.isNotEmpty ? _songs : _suggestions, startIndex: 0);
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: const Text('PLAY ALL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.shuffle_rounded),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: colorScheme.surfaceContainerHigh,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                  if (_biography.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outlineVariant.withAlpha(40))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biography', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                          const SizedBox(height: 8),
                          Text(_biography, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(180), height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildShimmerTrackTile(colorScheme),
                  childCount: 6,
                ),
              ),
            )
          else ...[
            if (_songs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = _songs[index];
                    return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Get.find<AudioPlayerController>().playAll(
                                _songs,
                                startIndex: index,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withAlpha(
                                    40,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${index + 1}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface
                                                .withAlpha(120),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song.thumbnailUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: song.thumbnailUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons.music_note_rounded,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons.music_note_rounded,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              Icons.music_note_rounded,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withAlpha(150),
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    song.source == MusicSource.youtube
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.music_note_rounded,
                                    color: colorScheme.primary.withAlpha(160),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (index * 50).ms)
                        .slideX(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        );
                  }, childCount: _songs.length),
                ),
              ),
            if (_songs.isEmpty &&
                !_isLoadingSuggestions &&
                _suggestions.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Text('No tracks found.'),
                  ),
                ),
              ),

            if (_suggestions.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_songs.isNotEmpty) const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recommended Songs',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = _suggestions[index];
                    return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Get.find<AudioPlayerController>().playAll(
                                _suggestions,
                                startIndex: index,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withAlpha(
                                    40,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: colorScheme.primary.withAlpha(120),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song.thumbnailUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: song.thumbnailUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons.music_note_rounded,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons.music_note_rounded,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              Icons.music_note_rounded,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withAlpha(150),
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    song.source == MusicSource.youtube
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.music_note_rounded,
                                    color: colorScheme.primary.withAlpha(160),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (index * 50).ms)
                        .slideX(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        );
                  }, childCount: _suggestions.length),
                ),
              ),
            ] else if (_isLoadingSuggestions)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerTrackTile(colorScheme),
                    childCount: 3,
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildShimmerTrackTile(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(40),
            ),
          ),
          child: Row(
            children: [
              Container(width: 20, height: 14, color: Colors.white),
              const SizedBox(width: 14),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 14, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 90, height: 10, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}
