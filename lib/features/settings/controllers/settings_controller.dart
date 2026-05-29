import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riftwave_music/core/models/region.dart';

enum ThemeVariant { dark, amoled }

class SettingsController extends GetxController {
  static const String _themeKey = 'theme_variant';
  static const String _qualityKey = 'audio_quality';
  static const String _regionKey = 'region_code';
  static const String _videoModeKey = 'video_mode';
  static const String _videoQualityKey = 'video_quality';
  static const String _dataWarningKey = 'has_seen_data_warning';

  final Rx<ThemeVariant> themeVariant = ThemeVariant.dark.obs;
  final RxString audioQuality = '320kbps'.obs;
  final RxString regionCode = 'IN'.obs;
  final RxBool videoModeEnabled = false.obs;
  final RxString videoQuality = 'Auto'.obs;
  final RxBool hasSeenDataWarning = false.obs;

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

    videoModeEnabled.value = prefs.getBool(_videoModeKey) ?? false;
    videoQuality.value = prefs.getString(_videoQualityKey) ?? 'Auto';
    hasSeenDataWarning.value = prefs.getBool(_dataWarningKey) ?? false;
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

  Future<void> setRegionCode(String code) async {
    regionCode.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, code);
  }

  Future<void> setVideoMode(bool enabled) async {
    videoModeEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_videoModeKey, enabled);
  }

  Future<void> setVideoQuality(String quality) async {
    videoQuality.value = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_videoQualityKey, quality);
  }

  Future<void> markDataWarningSeen() async {
    hasSeenDataWarning.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataWarningKey, true);
  }

  bool get isAmoled => themeVariant.value == ThemeVariant.amoled;
}
