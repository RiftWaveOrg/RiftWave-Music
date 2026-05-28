import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/core/utils/color_extractor.dart';






class DynamicColorController extends GetxController {
  final Rx<Color> dominantColor = const Color(0xFF6C63FF).obs;
  final Rx<Color> accentColor = const Color(0xFF9D97FF).obs;
  final RxBool isExtracting = false.obs;

  
  Future<void> extractFromImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    isExtracting.value = true;
    final palette = await ColorExtractor.extractFromUrl(imageUrl);
    dominantColor.value = ColorExtractor.getDominantColor(palette);
    accentColor.value = ColorExtractor.getAccentColor(palette);
    isExtracting.value = false;
  }

  
  void reset() {
    dominantColor.value = const Color(0xFF6C63FF);
    accentColor.value = const Color(0xFF9D97FF);
  }
}
