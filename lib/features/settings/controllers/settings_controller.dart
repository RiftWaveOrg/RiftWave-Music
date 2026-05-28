import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum ThemeVariant { dark, amoled }






class SettingsController extends GetxController {
  static const String _themeKey = 'theme_variant';

  final Rx<ThemeVariant> themeVariant = ThemeVariant.dark.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    if (stored == 'amoled') {
      themeVariant.value = ThemeVariant.amoled;
    } else {
      themeVariant.value = ThemeVariant.dark;
    }
  }

  Future<void> setThemeVariant(ThemeVariant variant) async {
    themeVariant.value = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, variant == ThemeVariant.amoled ? 'amoled' : 'dark');
  }

  bool get isAmoled => themeVariant.value == ThemeVariant.amoled;
}
