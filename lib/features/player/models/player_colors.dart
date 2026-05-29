import 'package:flutter/material.dart';

class PlayerColors {
  final Color background;
  final Color gradientTop;
  final Color gradientMid;
  final Color accent;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color seekbarActive;
  final Color seekbarInactive;
  final Color glowColor;

  const PlayerColors({
    required this.background,
    required this.gradientTop,
    required this.gradientMid,
    required this.accent,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.seekbarActive,
    required this.seekbarInactive,
    required this.glowColor,
  });

  const PlayerColors.defaultColors()
      : background = const Color(0xFF0D0B1A),
        gradientTop = const Color(0xFF1A1540),
        gradientMid = const Color(0xFF130F2A),
        accent = const Color(0xFF6C63FF),
        surface = const Color(0xFF1E1A35),
        textPrimary = const Color(0xFFFFFFFF),
        textSecondary = const Color(0xB3FFFFFF),
        seekbarActive = const Color(0xFF6C63FF),
        seekbarInactive = const Color(0x33FFFFFF),
        glowColor = const Color(0xFF6C63FF);
}
