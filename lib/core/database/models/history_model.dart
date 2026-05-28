import 'package:hive/hive.dart';

part 'history_model.g.dart';

@HiveType(typeId: 2)
class HistoryModel extends HiveObject {
  @HiveField(0)
  final String songId; 

  @HiveField(1)
  final DateTime playedAt;

  @HiveField(2)
  final int playDurationMs; 

  HistoryModel({
    required this.songId,
    DateTime? playedAt,
    this.playDurationMs = 0,
  }) : playedAt = playedAt ?? DateTime.now();

  @override
  String toString() =>
      'HistoryModel(songId: $songId, playedAt: $playedAt)';
}
