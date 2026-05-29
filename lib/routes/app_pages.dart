import 'package:get/get.dart';
import 'package:riftwave_music/routes/app_routes.dart';
import 'package:riftwave_music/features/home/bindings/home_binding.dart';
import 'package:riftwave_music/features/search/bindings/search_binding.dart';
import 'package:riftwave_music/features/player/bindings/player_binding.dart';
import 'package:riftwave_music/features/library/bindings/library_binding.dart';
import 'package:riftwave_music/features/settings/bindings/settings_binding.dart';
import 'package:riftwave_music/features/home/views/home_screen.dart';
import 'package:riftwave_music/features/search/views/search_screen.dart';
import 'package:riftwave_music/features/player/views/player_screen.dart';
import 'package:riftwave_music/features/library/views/library_screen.dart';
import 'package:riftwave_music/features/settings/views/settings_screen.dart';
import 'package:riftwave_music/shared/views/main_navigation.dart';
import 'package:riftwave_music/features/library/views/playlist_view_screen.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.main;

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.main,
      page: () => const MainNavigation(),
      bindings: [
        HomeBinding(),
        SearchBinding(),
        LibraryBinding(),
        SettingsBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerScreen(),
      binding: PlayerBinding(),
    ),
    GetPage(
      name: AppRoutes.library,
      page: () => const LibraryScreen(),
      binding: LibraryBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.likedSongs,
      page: () => const PlaylistViewScreen(isLikedSongs: true),
    ),
    GetPage(
      name: AppRoutes.downloadedSongs,
      page: () => const PlaylistViewScreen(isDownloadedSongs: true),
    ),
    GetPage(
      name: AppRoutes.playlistDetail,
      page: () => PlaylistViewScreen(playlist: Get.arguments),
    ),
  ];
}
