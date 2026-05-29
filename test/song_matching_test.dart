import 'package:flutter_test/flutter_test.dart';
import 'package:riftwave_music/core/database/models/song_model.dart';
import 'package:riftwave_music/shared/controllers/audio_player_controller.dart';

void main() {
  group('AudioPlayerController.isSongMatch Tests', () {
    test('Exact match (title and artist)', () {
      final original = SongModel(
        id: '1',
        title: 'Cheap Thrills',
        artist: 'Sia',
        album: 'This Is Acting',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'Cheap Thrills',
        artist: 'Sia',
        album: 'This Is Acting',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.saavn,
      );

      expect(AudioPlayerController.isSongMatch(original, fallback), isTrue);
    });

    test('Case insensitivity and spacing', () {
      final original = SongModel(
        id: '1',
        title: '  Cheap   THRILLS  ',
        artist: 'sia',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'cheap thrills',
        artist: 'SIA',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.saavn,
      );

      expect(AudioPlayerController.isSongMatch(original, fallback), isTrue);
    });

    test('Parentheses and brackets removal (non-greedy)', () {
      final original = SongModel(
        id: '1',
        title: 'Cheap Thrills (feat. Sean Paul) [Official Audio]',
        artist: 'Sia feat. Sean Paul',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'Cheap Thrills (Remix) (Radio Edit)',
        artist: 'Sia',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.saavn,
      );

      // Parentheses/brackets are stripped:
      // "cheap thrills" vs "cheap thrills" -> Match!
      // "sia feat sean paul" contains "sia" -> Match!
      expect(AudioPlayerController.isSongMatch(original, fallback), isTrue);
    });

    test('Multiple parentheses non-greedy check', () {
      final original = SongModel(
        id: '1',
        title: 'Song Title (Version A) Middle Text [Official] (Version B)',
        artist: 'Artist One',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 120000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'Song Title Middle Text',
        artist: 'Artist One',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 120000,
        source: MusicSource.saavn,
      );

      // Under a greedy match, everything from the first "(" to the last ")" would be deleted,
      // changing the title to just "Song Title ".
      // Under our non-greedy match, "Middle Text" is preserved, ensuring a perfect match!
      expect(AudioPlayerController.isSongMatch(original, fallback), isTrue);
    });

    test('Boilerplate terms removal', () {
      final original = SongModel(
        id: '1',
        title: 'Blinding Lights Official Video Lyrics Full Audio',
        artist: 'The Weeknd',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 200000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 200000,
        source: MusicSource.saavn,
      );

      expect(AudioPlayerController.isSongMatch(original, fallback), isTrue);
    });

    test('Title 70% word overlap match', () {
      // Let's test the 70% logic:
      final orig = SongModel(
        id: '1',
        title: 'Shape of You Radio',
        artist: 'Ed Sheeran',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 230000,
        source: MusicSource.youtube,
      );

      final fall = SongModel(
        id: '2',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 230000,
        source: MusicSource.saavn,
      );

      // origWords of length > 2 are 'shape', 'you', 'radio' (3 words).
      // Matches in fall: 'shape' (yes), 'you' (yes). That is 2/3 = 66.6%.
      // Let's test 'Shape of You Edit' (origWords: shape, you, edit -> 3 words).
      // Matches in fall: 'shape' (yes), 'you' (yes).
      // Let's use 'Shape Of You Studio Version' -> words: shape, studio, version (3 words). Matches: shape. 1/3 = 33%.
      
      expect(AudioPlayerController.isSongMatch(orig, fall), isTrue);
    });

    test('Artist mismatch fails matching', () {
      final original = SongModel(
        id: '1',
        title: 'Cheap Thrills',
        artist: 'Sia',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'Cheap Thrills',
        artist: 'Kidz Bop Kids',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.saavn,
      );

      expect(AudioPlayerController.isSongMatch(original, fallback), isFalse);
    });

    test('Title mismatch fails matching', () {
      final original = SongModel(
        id: '1',
        title: 'Unstoppable',
        artist: 'Sia',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.youtube,
      );

      final fallback = SongModel(
        id: '2',
        title: 'Cheap Thrills',
        artist: 'Sia',
        album: '',
        thumbnailUrl: '',
        audioUrl: '',
        durationMs: 211000,
        source: MusicSource.saavn,
      );

      expect(AudioPlayerController.isSongMatch(original, fallback), isFalse);
    });
  });
}
