import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 24),
            Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 28),

            _buildSectionTitle(theme, 'Appearance'),
            const SizedBox(height: 12),
            Obx(() => _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.dark_mode_rounded,
              title: 'Theme',
              subtitle: controller.isAmoled ? 'AMOLED Black' : 'Dark',
              onTap: () => _showThemeDialog(context),
            )).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'Playback'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.high_quality_rounded,
              title: 'Audio Quality',
              subtitle: 'High (320kbps)',
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.download_rounded,
              title: 'Download Quality',
              subtitle: 'High (320kbps)',
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'About'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: '1.0.0',
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.code_rounded,
              title: 'Source Code',
              subtitle: 'GitHub — Open Source (GPL v3)',
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'No tracking, no ads, no account',
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSettingsTile({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(120),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Choose Theme'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              colorScheme: colorScheme,
              title: 'Dark',
              subtitle: 'Deep dark gray backgrounds',
              variant: ThemeVariant.dark,
              selected: controller.themeVariant.value == ThemeVariant.dark,
              onTap: () => controller.setThemeVariant(ThemeVariant.dark),
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              colorScheme: colorScheme,
              title: 'AMOLED Black',
              subtitle: 'True black for OLED screens',
              variant: ThemeVariant.amoled,
              selected: controller.themeVariant.value == ThemeVariant.amoled,
              onTap: () => controller.setThemeVariant(ThemeVariant.amoled),
            ),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Done',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required ThemeVariant variant,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? colorScheme.primary.withAlpha(25)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withAlpha(80),
                    width: 2,
                  ),
                  color: selected ? colorScheme.primary : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(120),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
