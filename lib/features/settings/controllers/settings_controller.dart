import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeVariant { dark, amoled }

class SettingsController extends GetxController {
  static const String _themeKey = 'theme_variant';
  static const String _qualityKey = 'audio_quality';

  final Rx<ThemeVariant> themeVariant = ThemeVariant.dark.obs;
  final RxString audioQuality = '320kbps'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString(_themeKey);
    if (storedTheme == 'amoled') {
      themeVariant.value = ThemeVariant.amoled;
    } else {
      themeVariant.value = ThemeVariant.dark;
    }

    audioQuality.value = prefs.getString(_qualityKey) ?? '320kbps';
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

  bool get isAmoled => themeVariant.value == ThemeVariant.amoled;
}
