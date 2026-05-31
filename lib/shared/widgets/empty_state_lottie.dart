import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum EmptyStateType {
  search,
  history,
  library,
  downloads,
  liked,
  lyrics
}

class EmptyStateLottie extends StatelessWidget {
  final EmptyStateType type;
  final String title;
  final String? subtitle;

  const EmptyStateLottie({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
  });

  String _getLottieUrl() {
    switch (type) {
      case EmptyStateType.search:
        return 'https://assets9.lottiefiles.com/packages/lf20_1wzq12s5.json'; 
      case EmptyStateType.history:
        return 'https://assets2.lottiefiles.com/packages/lf20_z9wz5uho.json'; 
      case EmptyStateType.library:
      case EmptyStateType.downloads:
      case EmptyStateType.liked:
        return 'https://assets4.lottiefiles.com/private_files/lf30_cgfdhxgx.json'; 
      case EmptyStateType.lyrics:
        return 'https://assets8.lottiefiles.com/packages/lf20_wnw499b4.json'; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              _getLottieUrl(),
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => 
                Icon(Icons.inbox_rounded, size: 64, color: colorScheme.onSurface.withAlpha(100)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(150),
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
