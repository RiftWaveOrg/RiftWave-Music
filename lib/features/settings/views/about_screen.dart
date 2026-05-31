import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('About RiftWave'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Image.asset('assets/images/RiftWave_logo.png', width: 100, height: 100),
            const SizedBox(height: 24),
            Text(
              'RiftWave Music',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              'Version ${controller.appVersion.value}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )),
            const SizedBox(height: 32),
            Text(
              'RiftWave is a free, open-source music streaming application built with Flutter. It provides high-quality audio streaming, lyrics support, dynamic theming, and an ad-free experience. All of your data is stored locally on your device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withAlpha(180),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            _buildLinkTile(
              colorScheme: colorScheme,
              icon: Icons.code_rounded,
              title: 'Source Code',
              subtitle: 'View the project on GitHub',
              url: 'https://github.com/Pratyush0803/RiftWave-Music',
            ),
            const SizedBox(height: 16),
            _buildLinkTile(
              colorScheme: colorScheme,
              icon: Icons.bug_report_rounded,
              title: 'Report an Issue',
              subtitle: 'Found a bug? Let us know',
              url: 'https://github.com/Pratyush0803/RiftWave-Music/issues',
            ),
            const SizedBox(height: 16),
            _buildLinkTile(
              colorScheme: colorScheme,
              icon: Icons.developer_mode_rounded,
              title: 'Developer',
              subtitle: 'Pratyush0803',
              url: 'https://github.com/Pratyush0803',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(150),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withAlpha(100), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
