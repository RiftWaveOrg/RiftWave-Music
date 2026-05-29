import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riftwave_music/shared/controllers/video_player_controller.dart';

class FullscreenVideoScreen extends StatefulWidget {
  const FullscreenVideoScreen({super.key});

  @override
  State<FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<FullscreenVideoScreen> {
  final VideoPlayerController controller = Get.find<VideoPlayerController>();
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: controller.videoController,
              controls: NoVideoControls,
              fit: BoxFit.contain,
            ),
            if (_showControls) ...[
              
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(150),
                      Colors.transparent,
                      Colors.black.withAlpha(150),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                  onPressed: () => Get.back(),
                ),
              ),
              
              Center(
                child: Obx(() {
                  final isPlaying = controller.audioController.isPlaying.value;
                  return IconButton(
                    iconSize: 64,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => controller.audioController.togglePlayPause(),
                  );
                }),
              ),
              
              Positioned(
                bottom: 20,
                left: 30,
                right: 30,
                child: Obx(() {
                  final position = controller.audioController.currentPosition.value;
                  final duration = controller.audioController.totalDuration.value;
                  return Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: position.inSeconds.toDouble(),
                          max: duration.inSeconds.toDouble(),
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Colors.white24,
                          onChanged: (val) {
                            controller.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
