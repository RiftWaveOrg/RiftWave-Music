import 'package:get/get.dart';










class AudioPlayerController extends GetxController {
  
  final RxString currentSongId = ''.obs;
  final RxString currentTitle = ''.obs;
  final RxString currentArtist = ''.obs;
  final RxString currentThumbnail = ''.obs;

  
  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final RxBool hasSong = false.obs;

  
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  
  final RxList<String> queue = <String>[].obs;
  final RxInt currentIndex = 0.obs;

  
  final RxBool isShuffled = false.obs;
  final RxInt repeatMode = 0.obs; 

  
  void togglePlayPause() {
    isPlaying.value = !isPlaying.value;
    
  }

  
  void next() {
    if (queue.isEmpty) return;
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
    }
    
  }

  
  void previous() {
    if (queue.isEmpty) return;
    if (currentIndex.value > 0) {
      currentIndex.value--;
    }
    
  }

  
  void toggleShuffle() {
    isShuffled.value = !isShuffled.value;
  }

  
  void cycleRepeat() {
    repeatMode.value = (repeatMode.value + 1) % 3;
  }

  
  void seekTo(Duration pos) {
    position.value = pos;
    
  }

  
  double get progress {
    if (duration.value.inMilliseconds == 0) return 0.0;
    return position.value.inMilliseconds / duration.value.inMilliseconds;
  }
}
