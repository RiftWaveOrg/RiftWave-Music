import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy is our Priority',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'No Data Collection',
              content: 'RiftWave Music does NOT collect, store, transmit, or share any personally identifiable information. We do not use analytics, crashlytics, or telemetry to track your usage.',
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Local Storage',
              content: 'All of your data, including search history, playlists, liked songs, and application settings, are stored locally on your device. We do not have access to this data.',
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'No Accounts or Sign In',
              content: 'You do not need to create an account or sign in to use RiftWave Music. The app functions completely anonymously.',
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Third-Party Services',
              content: 'RiftWave Music acts as a client to fetch metadata and audio from public APIs (such as YouTube, JioSaavn, and Last.fm). By using the app, your device makes direct requests to these services. These third-party services may log your IP address as part of their standard operations.',
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Open Source & Transparent\nAvailable on GitHub',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(120),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withAlpha(180),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
