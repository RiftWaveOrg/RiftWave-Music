import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/features/settings/views/about_screen.dart';
import 'package:riftwave_music/features/settings/views/privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riftwave_music/shared/controllers/update_controller.dart';
import 'package:riftwave_music/core/models/region.dart';
import 'package:riftwave_music/features/settings/views/yt_login_screen.dart' as rift_yt;

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
            
            const SizedBox(height: 8),
            Obx(() => _buildSettingsSwitchTile(
              colorScheme: colorScheme,
              icon: Icons.lens_blur_rounded,
              title: 'Ambient Light Effect',
              subtitle: 'Dynamic glowing sweeps behind music players',
              value: controller.ambientLightEnabled.value,
              onChanged: (val) {
                controller.setAmbientLight(val);
              },
            )).animate().fadeIn(duration: 400.ms, delay: 120.ms),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'Music Discovery'),
            const SizedBox(height: 12),
            Obx(() {
              final region = controller.currentRegion;
              return _buildSettingsTile(
                colorScheme: colorScheme,
                icon: Icons.public_rounded,
                title: 'Music Region',
                subtitle: region.name,
                onTap: () => _showRegionPicker(context),
              );
            }).animate().fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'Playback'),
            const SizedBox(height: 12),
            Obx(() {
              String subtitle = 'Ultra (320kbps)';
              final q = controller.audioQuality.value;
              if (q == '48kbps') subtitle = 'Data Saver (48kbps)';
              if (q == '96kbps') subtitle = 'Standard (96kbps)';
              if (q == '160kbps') subtitle = 'High (160kbps)';
              if (q == '320kbps') subtitle = 'Ultra (320kbps)';

              return _buildSettingsTile(
                colorScheme: colorScheme,
                icon: Icons.high_quality_rounded,
                title: 'Audio Quality',
                subtitle: subtitle,
                onTap: () => _showAudioQualityDialog(context),
              );
            }).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.download_rounded,
              title: 'Download Quality',
              subtitle: 'High (320kbps)',
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'Video Playback'),
            const SizedBox(height: 12),
            Obx(() => _buildSettingsSwitchTile(
              colorScheme: colorScheme,
              icon: Icons.video_library_rounded,
              title: 'Music Video Mode',
              subtitle: 'Play HD music videos (YouTube only)',
              value: controller.videoModeEnabled.value,
              onChanged: (val) {
                controller.setVideoMode(val);
                if (val && !controller.hasSeenDataWarning.value) {
                  _showDataWarning(context);
                }
              },
            )).animate().fadeIn(duration: 400.ms, delay: 280.ms),
            const SizedBox(height: 8),
            Obx(() {
              if (!controller.videoModeEnabled.value) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.hd_rounded,
                  title: 'Video Quality',
                  subtitle: controller.videoQuality.value,
                  onTap: () => _showVideoQualityDialog(context),
                ),
              ).animate().fadeIn(duration: 200.ms);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'When enabled, music videos play for YouTube songs with no ads. JioSaavn songs always play audio only. Video streaming uses more mobile data.',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(120),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'YouTube Integration (Beta)'),
            const SizedBox(height: 12),
            Obx(() => _buildSettingsTile(
              colorScheme: colorScheme,
              iconWidget: controller.isYouTubeLoggedIn.value && controller.ytAvatarUrl.value.isNotEmpty
                  ? CircleAvatar(
                      radius: 12,
                      backgroundImage: CachedNetworkImageProvider(controller.ytAvatarUrl.value),
                    )
                  : Icon(
                      controller.isYouTubeLoggedIn.value 
                          ? Icons.check_circle_rounded 
                          : Icons.account_circle_rounded,
                      color: colorScheme.primary,
                    ),
              title: controller.isYouTubeLoggedIn.value 
                  ? 'YouTube Account' 
                  : 'Login to YouTube',
              subtitle: controller.isYouTubeLoggedIn.value
                  ? 'Manage your connected YouTube account'
                  : 'Unlock personalized recommendations and fix rate limits',
              onTap: () {
                _showYouTubeAccountDialog(context, controller, colorScheme);
              },
            )).animate().fadeIn(duration: 400.ms, delay: 285.ms),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'RiftWave is privacy-first. Your login cookies stay on this device and are only used to connect to YouTube.',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(120),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'Advanced'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.battery_charging_full_rounded,
              title: 'Background Activity',
              subtitle: 'Allow app to run in background without restrictions',
              onTap: () => controller.requestBackgroundActivity(),
            ).animate().fadeIn(duration: 400.ms, delay: 290.ms),

            const SizedBox(height: 24),

            _buildSectionTitle(theme, 'About'),
            const SizedBox(height: 12),
            Obx(() => _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: controller.appVersion.value,
              onTap: () => Get.to(() => const AboutScreen()),
            )).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.system_update_rounded,
              title: 'Check for Updates',
              subtitle: 'Tap to check for the latest version',
              onTap: () async {
                if (Get.isRegistered<UpdateController>()) {
                  final updateCtrl = Get.find<UpdateController>();
                  
                  Get.dialog(
                    Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                    barrierDismissible: false,
                  );
                  
                  final hasUpdate = await updateCtrl.checkForUpdatesManual();
                  
                  if (Get.isDialogOpen ?? false) {
                    Get.back(); 
                  }
                  
                  if (hasUpdate) {
                    updateCtrl.showUpdateDialog();
                  } else {
                    Get.snackbar(
                      'Up to Date', 
                      'You are already on the latest version.', 
                      snackPosition: SnackPosition.BOTTOM, 
                      margin: const EdgeInsets.all(16), 
                      backgroundColor: const Color(0xFF000000), 
                      colorText: const Color(0xFFFFFFFF)
                    );
                  }
                }
              },
            ).animate().fadeIn(duration: 400.ms, delay: 320.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.code_rounded,
              title: 'Source Code',
              subtitle: 'GitHub — Open Source (GPL v3)',
              onTap: () async {
                final url = Uri.parse('https://github.com/NazomiOrg/Nazomi-App');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.developer_mode_rounded,
              title: 'Developer',
              subtitle: 'Made with ❤️ by Pratyush0803',
              onTap: () async {
                final url = Uri.parse('https://github.com/Pratyush0803');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ).animate().fadeIn(duration: 400.ms, delay: 380.ms),
            const SizedBox(height: 8),
            _buildSettingsTile(
              colorScheme: colorScheme,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'No tracking, no ads, no accounts',
              onTap: () => Get.to(() => const PrivacyScreen()),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/RiftWave_logo.png', width: 64, height: 64),
                  const SizedBox(height: 12),
                  Text(
                    'RiftWave',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 800.ms, delay: 500.ms),
            ),
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
    IconData? icon,
    Widget? iconWidget,
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
                child: Center(
                  child: iconWidget ?? Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 20,
                  ),
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

  void _showRegionPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    final filteredRegions = MusicRegion.all.obs;

    searchController.addListener(() {
      final query = searchController.text.toLowerCase();
      if (query.isEmpty) {
        filteredRegions.assignAll(MusicRegion.all);
      } else {
        filteredRegions.assignAll(
          MusicRegion.all.where((r) => r.name.toLowerCase().contains(query)),
        );
      }
    });

    Get.dialog(
      Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Choose Your Region',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Songs, artists & playlists will be tailored to your region',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchController,
                  autofocus: false,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search region...',
                    hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(90)),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredRegions.length,
                  itemBuilder: (context, index) {
                    final region = filteredRegions[index];
                    return Obx(() {
                      final isSelected = controller.regionCode.value == region.code;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            controller.setRegionCode(region.code);
                            Get.back();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withAlpha(30)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    region.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                )),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSwitchTile({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: colorScheme.primary,
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

  void _showAudioQualityDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Choose Audio Quality'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption(
              colorScheme: colorScheme,
              title: 'Data Saver',
              subtitle: '48 kbps — Lowest data usage',
              quality: '48kbps',
              selected: controller.audioQuality.value == '48kbps',
              onTap: () => controller.setAudioQuality('48kbps'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: 'Standard',
              subtitle: '96 kbps — Balanced quality/data',
              quality: '96kbps',
              selected: controller.audioQuality.value == '96kbps',
              onTap: () => controller.setAudioQuality('96kbps'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: 'High',
              subtitle: '160 kbps — High fidelity sound',
              quality: '160kbps',
              selected: controller.audioQuality.value == '160kbps',
              onTap: () => controller.setAudioQuality('160kbps'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: 'Ultra',
              subtitle: '320 kbps — Highest audio depth',
              quality: '320kbps',
              selected: controller.audioQuality.value == '320kbps',
              onTap: () => controller.setAudioQuality('320kbps'),
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

  void _showVideoQualityDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Choose Video Quality'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption(
              colorScheme: colorScheme,
              title: 'Auto',
              subtitle: 'Best available quality',
              quality: 'Auto',
              selected: controller.videoQuality.value == 'Auto',
              onTap: () => controller.setVideoQuality('Auto'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: '1080p',
              subtitle: 'Full HD',
              quality: '1080p',
              selected: controller.videoQuality.value == '1080p',
              onTap: () => controller.setVideoQuality('1080p'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: '720p',
              subtitle: 'HD',
              quality: '720p',
              selected: controller.videoQuality.value == '720p',
              onTap: () => controller.setVideoQuality('720p'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: '480p',
              subtitle: 'Standard Definition',
              quality: '480p',
              selected: controller.videoQuality.value == '480p',
              onTap: () => controller.setVideoQuality('480p'),
            ),
            const SizedBox(height: 8),
            _buildQualityOption(
              colorScheme: colorScheme,
              title: '360p',
              subtitle: 'Data Saver',
              quality: '360p',
              selected: controller.videoQuality.value == '360p',
              onTap: () => controller.setVideoQuality('360p'),
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

  void _showDataWarning(BuildContext context) async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.mobile)) {
      Get.defaultDialog(
        title: 'Data Usage Warning',
        middleText: 'Music videos use significantly more mobile data than audio. Consider enabling Data Saver mode or using WiFi.',
        textConfirm: 'Got it',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        onConfirm: () {
          controller.markDataWarningSeen();
          Get.back();
        },
        onCancel: () {
          controller.setVideoMode(false);
        },
      );
    } else {
      controller.markDataWarningSeen();
    }
  }

  Widget _buildQualityOption({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required String quality,
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

  void _showYouTubeAccountDialog(BuildContext context, SettingsController controller, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Obx(() {
          final bool isLoggedIn = controller.isYouTubeLoggedIn.value;
          final String avatar = controller.ytAvatarUrl.value;
          final String name = controller.ytAccountName.value;
          final String handle = controller.ytAccountHandle.value;
          
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_rounded, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'YouTube Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        backgroundImage: isLoggedIn && avatar.isNotEmpty 
                            ? CachedNetworkImageProvider(avatar)
                            : null,
                        child: (!isLoggedIn || avatar.isEmpty)
                            ? Icon(Icons.person, size: 32, color: colorScheme.onSurfaceVariant)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn ? 'YouTube Account' : 'Guest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isLoggedIn ? 'Signed in' : 'Not signed in',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoggedIn)
                        IconButton(
                          icon: Icon(Icons.logout, color: colorScheme.error),
                          tooltip: 'Log out from YouTube',
                          onPressed: () async {
                            await controller.logoutYouTube();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(isLoggedIn ? 'Switch / Add Account' : 'Add an Account'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Get.to(() => const rift_yt.YouTubeLoginScreen());
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
