import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String thumbnailUrl;

  @HiveField(5)
  final String audioUrl;

  @HiveField(6)
  final int durationMs;

  @HiveField(7)
  final String source;

  @HiveField(8)
  final String sourceId;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.thumbnailUrl = '',
    this.audioUrl = '',
    this.durationMs = 0,
    this.source = 'youtube',
    this.sourceId = '',
  });

  @override
  String toString() => 'SongModel(title: $title, artist: $artist)';
}
