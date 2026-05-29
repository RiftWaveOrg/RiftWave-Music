import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ColorExtractor {

  static Future<PaletteGenerator?> extractFromUrl(String imageUrl) async {
    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      return await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 8,
      );
    } catch (e) {
      debugPrint('ColorExtractor: Failed to extract colors — $e');
      return null;
    }
  }

  static Color getDominantColor(PaletteGenerator? palette) {
    if (palette == null) return const Color(0xFF6C63FF);
    return palette.dominantColor?.color ??
        palette.vibrantColor?.color ??
        const Color(0xFF6C63FF);
  }

  static Color getAccentColor(PaletteGenerator? palette) {
    if (palette == null) return const Color(0xFF9D97FF);
    return palette.lightVibrantColor?.color ??
        palette.lightMutedColor?.color ??
        const Color(0xFF9D97FF);
  }
}
