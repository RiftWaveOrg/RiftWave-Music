import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riftwave_music/features/home/views/home_screen.dart';
import 'package:riftwave_music/features/search/views/search_screen.dart';
import 'package:riftwave_music/features/library/views/library_screen.dart';
import 'package:riftwave_music/features/settings/views/settings_screen.dart';
import 'package:riftwave_music/shared/widgets/mini_player.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(MainNavController());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: navController.currentIndex.value,
        children: const [
          HomeScreen(),
          SearchScreen(),
          LibraryScreen(),
          SettingsScreen(),
        ],
      )),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const MiniPlayer(),

          Obx(() => NavigationBar(
            selectedIndex: navController.currentIndex.value,
            onDestinationSelected: navController.changeTab,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: colorScheme.onSurface.withAlpha(153),
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: colorScheme.primary,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurface.withAlpha(153),
                ),
                selectedIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.library_music_outlined,
                  color: colorScheme.onSurface.withAlpha(153),
                ),
                selectedIcon: Icon(
                  Icons.library_music_rounded,
                  color: colorScheme.primary,
                ),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/RiftWave_logo.png',
                  width: 24,
                  height: 24,
                  color: colorScheme.onSurface.withAlpha(153),
                ),
                selectedIcon: Image.asset(
                  'assets/images/RiftWave_logo.png',
                  width: 24,
                  height: 24,
                  color: colorScheme.primary,
                ),
                label: 'Settings',
              ),
            ],
          ).animate().fadeIn(duration: 500.ms)),
        ],
      ),
    );
  }
}

class MainNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
