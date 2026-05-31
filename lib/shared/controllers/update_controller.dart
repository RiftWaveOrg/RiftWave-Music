import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdateController extends GetxController {
  final RxBool updateAvailable = false.obs;
  final RxString latestVersion = ''.obs;
  final RxString changelog = ''.obs;
  final RxString apkDownloadUrl = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkForUpdates();
  }

  Future<String?> _findMatchingApkUrl(List<dynamic> assets) async {
    if (!Platform.isAndroid) return null;
    
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final supportedAbis = androidInfo.supportedAbis;
    
    String? arm64Apk;
    String? arm32Apk;
    String? x86_64Apk;
    String? fallbackApk;
    
    for (var asset in assets) {
      final name = (asset['name'] as String).toLowerCase();
      if (!name.endsWith('.apk')) continue;
      
      final url = asset['browser_download_url'] as String;
      if (name.contains('arm64') || name.contains('v8a')) {
        arm64Apk = url;
      } else if (name.contains('arm32') || name.contains('v7a') || name.contains('armeabi')) {
        arm32Apk = url;
      } else if (name.contains('x86_64') || name.contains('x64')) {
        x86_64Apk = url;
      } else {
        fallbackApk = url;
      }
    }
    
    for (var abi in supportedAbis) {
      if (abi.contains('arm64-v8a') && arm64Apk != null) return arm64Apk;
      if (abi.contains('armeabi-v7a') && arm32Apk != null) return arm32Apk;
      if (abi.contains('x86_64') && x86_64Apk != null) return x86_64Apk;
    }
    
    return arm64Apk ?? arm32Apk ?? fallbackApk;
  }

  Future<void> _checkForUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get('https://api.github.com/repos/Pratyush0803/RiftWave-Music/releases/latest');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String;
        final releaseBody = _cleanChangelog((data['body'] as String?) ?? '');
        
        // Remove 'v' from tag if present (e.g. 'v1.2.0' -> '1.2.0')
        final String githubVersion = latestTag.startsWith('v') ? latestTag.substring(1) : latestTag;
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, githubVersion)) {
          final prefs = await SharedPreferences.getInstance();
          final skippedVersion = prefs.getString('skipped_version');
          
          if (skippedVersion != githubVersion) {
            latestVersion.value = latestTag;
            changelog.value = releaseBody;
            
            // Find APK asset
            final assets = data['assets'] as List<dynamic>;
            final matchUrl = await _findMatchingApkUrl(assets);
            if (matchUrl != null) {
              apkDownloadUrl.value = matchUrl;
            }
            
            updateAvailable.value = true;
            showUpdateDialog();
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  String _cleanChangelog(String body) {
    String cleaned = body;
    // Remove the generic GitHub changelog link
    final idx = cleaned.indexOf('**Full Changelog**:');
    if (idx != -1) {
      cleaned = cleaned.substring(0, idx).trim();
    }
    
    // Clean up basic markdown headers and bolding so it looks good in a raw Text widget
    cleaned = cleaned.replaceAll('## What\'s Changed', 'What\'s Changed:');
    cleaned = cleaned.replaceAll('**What\'s Changed**', 'What\'s Changed:');
    cleaned = cleaned.replaceAll('**', ''); // Remove bold markers
    cleaned = cleaned.replaceAll('##', ''); // Remove other header markers
    
    if (cleaned.trim().isEmpty) {
      return '• Bug fixes and performance improvements.\n• General app optimizations.';
    }
    return cleaned.trim();
  }

  Future<bool> checkForUpdatesManual() async {
    try {
      final dio = Dio();
      final response = await dio.get('https://api.github.com/repos/Pratyush0803/RiftWave-Music/releases/latest');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String;
        final releaseBody = _cleanChangelog((data['body'] as String?) ?? '');
        
        final String githubVersion = latestTag.startsWith('v') ? latestTag.substring(1) : latestTag;
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, githubVersion)) {
          latestVersion.value = latestTag;
          changelog.value = releaseBody;
          
          final assets = data['assets'] as List<dynamic>;
          final matchUrl = await _findMatchingApkUrl(assets);
          if (matchUrl != null) {
            apkDownloadUrl.value = matchUrl;
          }
          
          updateAvailable.value = true;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Manual update check failed: $e');
    }
    return false;
  }

  bool _isNewerVersion(String current, String latest) {
    List<int> currParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    
    // pad to same length
    while (currParts.length < 3) currParts.add(0);
    while (latestParts.length < 3) latestParts.add(0);
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currParts[i]) return true;
      if (latestParts[i] < currParts[i]) return false;
    }
    return false;
  }

  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skipped_version', version.startsWith('v') ? version.substring(1) : version);
    updateAvailable.value = false;
  }

  Future<void> startUpdate() async {
    // Fallback for Web and Desktop (Windows, macOS, Linux)
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final Uri githubUrl = Uri.parse('https://github.com/Pratyush0803/RiftWave-Music/releases/latest');
      if (await canLaunchUrl(githubUrl)) {
        await launchUrl(githubUrl, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (Platform.isIOS) {
      final Uri appStoreUrl = Uri.parse('https://apps.apple.com/');
      if (await canLaunchUrl(appStoreUrl)) {
        await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
      }
      return;
    }
    
    if (Platform.isAndroid) {
      try {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          final req = await Permission.requestInstallPackages.request();
          if (req.isDenied) {
            Get.snackbar('Permission Required', 'Cannot install update without permission.', backgroundColor: const Color(0xFF000000), colorText: const Color(0xFFFFFFFF), snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
            return;
          }
        }
        
        isDownloading.value = true;
        downloadProgress.value = 0.0;
        
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/riftwave-update.apk';
        
        final dio = Dio();
        await dio.download(
          apkDownloadUrl.value,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              downloadProgress.value = received / total;
            }
          },
        );
        
        isDownloading.value = false;
        
        final result = await OpenFile.open(savePath);
        if (result.type != ResultType.done) {
          Get.snackbar('Update Failed', result.message ?? 'Unknown error', backgroundColor: const Color(0xFF000000), colorText: const Color(0xFFFFFFFF), snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        }
      } catch (e) {
        isDownloading.value = false;
        Get.snackbar('Update Failed', 'An error occurred during download.', backgroundColor: const Color(0xFF000000), colorText: const Color(0xFFFFFFFF), snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        debugPrint(e.toString());
      }
    }
  }
  void showUpdateDialog() {
    final colorScheme = Get.theme.colorScheme;
    Get.dialog(
      AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.system_update_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${latestVersion.value} is available!',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Text(changelog.value, style: TextStyle(color: colorScheme.onSurface.withAlpha(200))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Later', style: TextStyle(color: colorScheme.onSurface.withAlpha(150))),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              startUpdate();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
