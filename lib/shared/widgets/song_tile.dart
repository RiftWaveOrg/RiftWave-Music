import 'package:flutter/material.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    this.onTap,
    this.trailing,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [

              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
                        ),
                      )
                    : _buildPlaceholder(colorScheme),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isPlaying
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      artist,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(120),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              trailing ??
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface.withAlpha(100),
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: colorScheme.primary.withAlpha(100),
        size: 22,
      ),
    );
  }
}
