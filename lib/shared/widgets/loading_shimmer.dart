import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 60,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHighest.withAlpha(120),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget songList({int count = 5}) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              const LoadingShimmer(width: 50, height: 50, borderRadius: 8),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer(
                      height: 14,
                      width: 120.0 + (index * 20 % 80),
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    const LoadingShimmer(
                      height: 10,
                      width: 80,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
