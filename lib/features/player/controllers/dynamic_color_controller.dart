import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/features/player/models/player_colors.dart';

class DynamicColorController extends GetxController {
  final Rx<PlayerColors> playerColors = const PlayerColors.defaultColors().obs;
  final RxBool isExtracting = false.obs;

  String _lastExtractedUrl = '';

  Future<void> extractFromImageUrl(String url) async {
    if (url.isEmpty) {
      playerColors.value = const PlayerColors.defaultColors();
      _lastExtractedUrl = '';
      return;
    }

    if (url == _lastExtractedUrl) return;
    _lastExtractedUrl = url;

    isExtracting.value = true;

    try {
      final imageProvider = CachedNetworkImageProvider(url);
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 16,
      );

      playerColors.value = _computeColors(palette);
    } catch (e) {
      debugPrint('DynamicColorController: Extraction failed — $e');
      playerColors.value = const PlayerColors.defaultColors();
    } finally {
      isExtracting.value = false;
    }
  }

  void reset() {
    playerColors.value = const PlayerColors.defaultColors();
    _lastExtractedUrl = '';
  }

  PlayerColors _computeColors(PaletteGenerator palette) {
    final Color dominant = palette.dominantColor?.color ?? const Color(0xFF6C63FF);
    final Color? vibrant = palette.vibrantColor?.color;
    final Color? darkVibrant = palette.darkVibrantColor?.color;
    final Color? lightVibrant = palette.lightVibrantColor?.color;
    final Color? darkMuted = palette.darkMutedColor?.color;

    final Color accent = vibrant ?? lightVibrant ?? dominant;

    Color background = darkVibrant ?? darkMuted ?? dominant;
    background = _ensureDark(background, maxLuminance: 0.15);

    final HSLColor bgHsl = HSLColor.fromColor(background);
    final Color gradientTop = bgHsl
        .withLightness((bgHsl.lightness + 0.12).clamp(0.0, 0.3))
        .withSaturation((bgHsl.saturation * 0.8).clamp(0.0, 1.0))
        .toColor();
    final Color gradientMid = bgHsl
        .withLightness((bgHsl.lightness + 0.05).clamp(0.0, 0.25))
        .toColor();

    final Color surface = bgHsl
        .withLightness((bgHsl.lightness + 0.08).clamp(0.0, 0.25))
        .withSaturation((bgHsl.saturation * 0.6).clamp(0.0, 1.0))
        .toColor();

    Color textPrimary = Colors.white;
    Color textSecondary = Colors.white.withAlpha(179);

    if (_contrastRatio(accent, background) < 3.0) {
      final HSLColor accentHsl = HSLColor.fromColor(accent);
      final Color adjustedAccent = accentHsl
          .withLightness((accentHsl.lightness + 0.2).clamp(0.4, 0.85))
          .toColor();
      return PlayerColors(
        background: background,
        gradientTop: gradientTop,
        gradientMid: gradientMid,
        accent: adjustedAccent,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        seekbarActive: adjustedAccent,
        seekbarInactive: Colors.white.withAlpha(51),
        glowColor: adjustedAccent,
      );
    }

    final HSLColor glowHsl = HSLColor.fromColor(accent);
    final Color glowColor = glowHsl
        .withSaturation((glowHsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();

    return PlayerColors(
      background: background,
      gradientTop: gradientTop,
      gradientMid: gradientMid,
      accent: accent,
      surface: surface,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      seekbarActive: accent,
      seekbarInactive: Colors.white.withAlpha(51),
      glowColor: glowColor,
    );
  }

  Color _ensureDark(Color color, {double maxLuminance = 0.3}) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness > maxLuminance) {
      return hsl.withLightness(maxLuminance * 0.6).toColor();
    }
    return color;
  }

  double _contrastRatio(Color fg, Color bg) {
    final double fgLum = _relativeLuminance(fg) + 0.05;
    final double bgLum = _relativeLuminance(bg) + 0.05;
    final double lighter = fgLum > bgLum ? fgLum : bgLum;
    final double darker = fgLum > bgLum ? bgLum : fgLum;
    return lighter / darker;
  }

  double _relativeLuminance(Color color) {
    double r = color.r / 255.0;
    double g = color.g / 255.0;
    double b = color.b / 255.0;

    r = r <= 0.03928 ? r / 12.92 : _gammaCorrect(r);
    g = g <= 0.03928 ? g / 12.92 : _gammaCorrect(g);
    b = b <= 0.03928 ? b / 12.92 : _gammaCorrect(b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _gammaCorrect(double value) {
    return ((value + 0.055) / 1.055);
  }
}
