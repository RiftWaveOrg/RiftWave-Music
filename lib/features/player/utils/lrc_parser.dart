import 'package:riftwave_music/features/player/models/lyric_line.dart';

class LrcParser {

  static List<LyricLine> parse(String lrcText) {
    if (lrcText.isEmpty) return [];

    int globalOffsetMs = 0;
    final RegExp offsetRegex = RegExp(r'\[offset:\s*([+-]?\d+)\s*\]', caseSensitive: false);
    final offsetMatch = offsetRegex.firstMatch(lrcText);
    if (offsetMatch != null) {
      globalOffsetMs = int.tryParse(offsetMatch.group(1) ?? '') ?? 0;
    }

    final List<LyricLine> lines = [];

    final RegExp timestampRegex = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\]');

    for (final line in lrcText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('[') && !trimmed.startsWith(RegExp(r'\[\d+'))) {
        continue;
      }

      final matches = timestampRegex.allMatches(trimmed).toList();
      if (matches.isEmpty) continue;

      final lastMatch = matches.last;
      final text = trimmed.substring(lastMatch.end).trim();

      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
        final secondsPart = match.group(2) ?? '0';

        final secondsParts = secondsPart.split('.');
        final seconds = int.tryParse(secondsParts[0]) ?? 0;

        int milliseconds = 0;
        if (secondsParts.length > 1) {
          final msStr = secondsParts[1];
          if (msStr.length == 1) {
            milliseconds = (int.tryParse(msStr) ?? 0) * 100;
          } else if (msStr.length == 2) {
            milliseconds = (int.tryParse(msStr) ?? 0) * 10;
          } else if (msStr.length >= 3) {
            milliseconds = int.tryParse(msStr.substring(0, 3)) ?? 0;
          }
        }

        final baseTime = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        final adjustedTime = baseTime + Duration(milliseconds: globalOffsetMs);
        final finalTime = adjustedTime.isNegative ? Duration.zero : adjustedTime;

        lines.add(LyricLine(finalTime, text));
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
