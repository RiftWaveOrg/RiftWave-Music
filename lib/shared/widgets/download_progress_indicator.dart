import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DownloadProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            color: color,
            backgroundColor: color.withAlpha(50),
          ),
          Icon(
            Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .moveY(
                begin: -3,
                end: 3,
                duration: 600.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: 3,
                end: -3,
                duration: 600.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }
}
