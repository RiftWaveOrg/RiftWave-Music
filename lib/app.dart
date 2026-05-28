import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:riftwave_music/core/theme/app_theme.dart';
import 'package:riftwave_music/routes/app_pages.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';






class RiftWaveApp extends StatelessWidget {
  const RiftWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Obx(() {
          final isAmoled = settingsController.isAmoled;

          final theme = isAmoled
              ? AppTheme.amoled(dynamicColorScheme: darkDynamic)
              : AppTheme.dark(dynamicColorScheme: darkDynamic);

          return GetMaterialApp(
            title: 'RiftWave Music',
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.dark,
            initialRoute: AppPages.initial,
            getPages: AppPages.routes,
            defaultTransition: Transition.fadeIn,
            transitionDuration: const Duration(milliseconds: 250),
          );
        });
      },
    );
  }
}
