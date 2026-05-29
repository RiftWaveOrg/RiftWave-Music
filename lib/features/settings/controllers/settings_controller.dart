import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riftwave_music/core/models/region.dart';

enum ThemeVariant { dark, amoled }

class SettingsController extends GetxController {
  static const String _themeKey = 'theme_variant';
  static const String _qualityKey = 'audio_quality';
  static const String _regionKey = 'region_code';

  final Rx<ThemeVariant> themeVariant = ThemeVariant.dark.obs;
  final RxString audioQuality = '320kbps'.obs;
  final RxString regionCode = 'IN'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  MusicRegion get currentRegion => MusicRegion.fromCode(regionCode.value);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString(_themeKey);
    if (storedTheme == 'amoled') {
      themeVariant.value = ThemeVariant.amoled;
    } else {
      themeVariant.value = ThemeVariant.dark;
    }

    audioQuality.value = prefs.getString(_qualityKey) ?? '320kbps';

    final storedRegion = prefs.getString(_regionKey);
    if (storedRegion != null) {
      regionCode.value = storedRegion;
    } else {
      regionCode.value = _detectRegionFromLocale();
    }
  }

  String _detectRegionFromLocale() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode ?? '';
      if (countryCode.isNotEmpty) {
        final region = MusicRegion.fromLocale(countryCode);
        return region.code;
      }
    } catch (_) {}
    return 'IN';
  }

  Future<void> setThemeVariant(ThemeVariant variant) async {
    themeVariant.value = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, variant == ThemeVariant.amoled ? 'amoled' : 'dark');
  }

  Future<void> setAudioQuality(String quality) async {
    audioQuality.value = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qualityKey, quality);
  }

  Future<void> setRegion(String code) async {
    regionCode.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, code);
  }

  bool get isAmoled => themeVariant.value == ThemeVariant.amoled;
}
