import 'package:flutter/material.dart';

class AppColorSchemes {
  AppColorSchemes._();

  static const Color brandColor = Color(0xFF6C63FF);

  static ColorScheme get dark {
    final base = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      surface: const Color(0xFF121212),
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF1E1E1E),
    );
  }

  static ColorScheme get amoled {
    final base = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF0A0A0A),
    );
  }

  static ColorScheme dynamicDark(ColorScheme systemDark) {
    return systemDark.copyWith(
      surface: const Color(0xFF121212),
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF1E1E1E),
    );
  }

  static ColorScheme dynamicAmoled(ColorScheme systemDark) {
    return systemDark.copyWith(
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF0A0A0A),
    );
  }
}
