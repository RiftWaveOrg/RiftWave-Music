import 'package:flutter_test/flutter_test.dart';
import 'package:riftwave_music/features/player/utils/lrc_parser.dart';

void main() {
  group('LrcParser Tests', () {
    test('Parse empty LRC returns empty list', () {
      final parsed = LrcParser.parse('');
      expect(parsed, isEmpty);
    });

    test('Strips metadata tags completely', () {
      const lrc = '''
[ti:Cheap Thrills]
[ar:Sia]
[al:This Is Acting]
[length:03:31]
[00:10.50]Come on, come on, turn the radio on
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(1));
      expect(parsed.first.text, equals('Come on, come on, turn the radio on'));
      expect(parsed.first.time, equals(const Duration(seconds: 10, milliseconds: 500)));
    });

    test('Handles multi-timestamp duplication and chronologically sorts', () {
      const lrc = '''
[00:20.15][00:40.30]Baby I do not need dollar bills to have fun tonight
[00:10.50]Come on, come on, turn the radio on
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(3));

      expect(parsed[0].time, equals(const Duration(seconds: 10, milliseconds: 500)));
      expect(parsed[0].text, equals('Come on, come on, turn the radio on'));

      expect(parsed[1].time, equals(const Duration(seconds: 20, milliseconds: 150)));
      expect(parsed[1].text, equals('Baby I do not need dollar bills to have fun tonight'));

      expect(parsed[2].time, equals(const Duration(seconds: 40, milliseconds: 300)));
      expect(parsed[2].text, equals('Baby I do not need dollar bills to have fun tonight'));
    });

    test('Handles millisecond precision with 1, 2, or 3 digits', () {
      const lrc = '''
[01:05.8]One digit
[01:10.45]Two digits
[01:15.123]Three digits
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(3));

      expect(parsed[0].time, equals(const Duration(minutes: 1, seconds: 5, milliseconds: 800)));
      expect(parsed[1].time, equals(const Duration(minutes: 1, seconds: 10, milliseconds: 450)));
      expect(parsed[2].time, equals(const Duration(minutes: 1, seconds: 15, milliseconds: 123)));
    });

    test('Parses positive global offset tag and delays lyrics', () {
      const lrc = '''
[ti:Cheap Thrills]
[offset:500]
[00:10.50]Come on, come on, turn the radio on
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(1));

      expect(parsed.first.time, equals(const Duration(seconds: 11)));
      expect(parsed.first.text, equals('Come on, come on, turn the radio on'));
    });

    test('Parses negative global offset tag and advances lyrics', () {
      const lrc = '''
[offset:-300]
[00:10.50]Come on, come on, turn the radio on
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(1));

      expect(parsed.first.time, equals(const Duration(seconds: 10, milliseconds: 200)));
    });

    test('Clamps negative global offset resulting times to zero', () {
      const lrc = '''
[offset:-5000]
[00:02.00]Lyric close to start
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(1));

      expect(parsed.first.time, equals(Duration.zero));
    });

    test('Handles spaces and case variations in offset tag', () {
      const lrc = '''
[OFFSET:   +400   ]
[00:01.00]Lyric line
''';
      final parsed = LrcParser.parse(lrc);
      expect(parsed, hasLength(1));
      expect(parsed.first.time, equals(const Duration(seconds: 1, milliseconds: 400)));
    });
  });
}
