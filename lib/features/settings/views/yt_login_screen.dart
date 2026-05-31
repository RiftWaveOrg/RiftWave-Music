import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';

class YouTubeLoginScreen extends StatefulWidget {
  const YouTubeLoginScreen({super.key});

  @override
  State<YouTubeLoginScreen> createState() => _YouTubeLoginScreenState();
}

class _YouTubeLoginScreenState extends State<YouTubeLoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) async {
            if (mounted) setState(() => _isLoading = false);
            await _checkCookiesAndExtractData(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?continue=https://www.youtube.com/?app=desktop'));
  }

  Future<void> _checkCookiesAndExtractData(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('youtube.com')) return;

    final String cookies = await _controller.runJavaScriptReturningResult('document.cookie') as String;
    final cleanedCookies = cookies.replaceAll('"', '').trim();

    if (cleanedCookies.contains('__Secure-1PAPISID') || cleanedCookies.contains('SAPISID')) {
      
      await Future.delayed(const Duration(seconds: 2));

      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('yt_cookies', cleanedCookies);

      
      String? extractedJsonStr;
      for (int attempt = 0; attempt < 20; attempt++) {
        extractedJsonStr = await _controller.runJavaScriptReturningResult('''
          (function() {
            let data = { avatar: null, name: null, handle: null };
            try {
              if (window.ytInitialData && window.ytInitialData.topbar) {
                const buttons = window.ytInitialData.topbar.desktopTopbarRenderer?.topbarButtons;
                if (buttons) {
                  const accountMenu = buttons.find(b => b.topbarMenuButtonRenderer?.avatar)?.topbarMenuButtonRenderer;
                  if (accountMenu) {
                    if (accountMenu.tooltip) data.name = accountMenu.tooltip;
                    const img = accountMenu.avatar?.thumbnails?.[0]?.url;
                    if (img) data.avatar = img;
                  }
                }
              }
            } catch(e) {}
            return JSON.stringify(data);
          })();
        ''') as String?;

        if (extractedJsonStr != null) {
          try {
            final unescaped = extractedJsonStr.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
            final String cleanJson = unescaped.startsWith('"') && unescaped.endsWith('"') 
                ? unescaped.substring(1, unescaped.length - 1) 
                : unescaped;
            final Map<String, dynamic> data = jsonDecode(cleanJson);
            if (data['name'] != null && data['avatar'] != null) break;
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (extractedJsonStr != null) {
        try {
          final unescaped = extractedJsonStr.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
          final String cleanJson = unescaped.startsWith('"') && unescaped.endsWith('"') 
              ? unescaped.substring(1, unescaped.length - 1) 
              : unescaped;
              
          final Map<String, dynamic> data = jsonDecode(cleanJson);
          
          if (data['avatar'] != null) {
            String avatarUrl = data['avatar'].toString();
            if (avatarUrl.startsWith('//')) {
              avatarUrl = 'https:' + avatarUrl;
            }
            await prefs.setString('yt_avatar_url', avatarUrl);
          }
          if (data['name'] != null) await prefs.setString('yt_account_name', data['name']);
          if (data['handle'] != null) await prefs.setString('yt_account_handle', data['handle']);
        } catch (e) {
          debugPrint('Failed to parse YouTube profile data: $e');
        }
      }


      
      if (Get.isRegistered<SettingsController>()) {
        await Get.find<SettingsController>().reloadYouTubeState();
      }

      
      if (Get.isRegistered<YouTubeApi>()) {
        await Get.find<YouTubeApi>().reloadCookies();
      }

      if (mounted) {
        Get.back();
        Get.snackbar(
          'Success',
          'Successfully logged into YouTube',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          colorText: Theme.of(context).colorScheme.onPrimaryContainer,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Login'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
