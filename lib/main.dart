import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riftwave_music/app.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/database/models/playlist_model.dart';
import 'package:riftwave_music/core/database/models/history_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  
  await Hive.initFlutter();

  
  Hive.registerAdapter(SongModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  Hive.registerAdapter(HistoryModelAdapter());

  
  Get.put(SettingsController(), permanent: true);
  Get.put(AudioPlayerController(), permanent: true);

  runApp(const RiftWaveApp());
}
