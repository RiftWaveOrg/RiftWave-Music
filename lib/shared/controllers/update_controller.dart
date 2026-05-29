import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _checkForUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get('https://api.github.com/repos/Pratyush0803/RiftWave-Music/releases/latest');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String;
        final releaseBody = data['body'] as String;
        
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
            for (var asset in assets) {
              final name = asset['name'] as String;
              if (name.endsWith('.apk')) {
                apkDownloadUrl.value = asset['browser_download_url'] as String;
                break;
              }
            }
            
            updateAvailable.value = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
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
            Get.snackbar('Permission Required', 'Cannot install update without permission.');
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
          Get.snackbar('Update Failed', result.message);
        }
      } catch (e) {
        isDownloading.value = false;
        Get.snackbar('Update Failed', 'An error occurred during download.');
        debugPrint(e.toString());
      }
    }
  }
}
