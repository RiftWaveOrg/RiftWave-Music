import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:riftwave_music/app.dart';
import 'package:riftwave_music/core/audio/audio_handler.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/core/database/models/playlist_model.dart';
import 'package:riftwave_music/core/database/models/history_model.dart';
import 'package:riftwave_music/core/api/youtube_api.dart';
import 'package:riftwave_music/core/api/saavn_api.dart';
import 'package:riftwave_music/core/api/lrclib_api.dart';
import 'package:riftwave_music/core/api/lastfm_api.dart';
import 'package:riftwave_music/features/settings/controllers/settings_controller.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

import 'package:riftwave_music/features/player/controllers/lyrics_controller.dart';
import 'package:riftwave_music/core/services/recommendation_engine.dart';
import 'package:riftwave_music/features/library/controllers/library_controller.dart';
import 'package:riftwave_music/shared/controllers/download_controller.dart';
import 'package:riftwave_music/shared/controllers/update_controller.dart';

import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();

  Hive.registerAdapter(MusicSourceAdapter());
  Hive.registerAdapter(SongModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  Hive.registerAdapter(HistoryModelAdapter());

  final audioHandler = await AudioService.init(
    builder: () => RiftWaveAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.riftwavemusic.app.channel.audio',
      androidNotificationChannelName: 'RiftWave Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationClickStartsActivity: true,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );

  Get.put<RiftWaveAudioHandler>(audioHandler, permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(YouTubeApi(), permanent: true);
  Get.put(SaavnApi(), permanent: true);
  Get.put(LrcLibApi(), permanent: true);
  Get.put(LastFmApi(), permanent: true);
  Get.put(AudioPlayerController(), permanent: true);
  Get.put(LyricsController(), permanent: true);
  Get.put(RecommendationEngine(), permanent: true);
  
  
  Get.put(DownloadController(), permanent: true);
  Get.put(UpdateController(), permanent: true);
  Get.lazyPut(() => LibraryController(), fenix: true);

  runApp(const RiftWaveApp());
}
