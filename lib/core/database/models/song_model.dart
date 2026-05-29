import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 4)
enum MusicSource {
  @HiveField(0)
  youtube,
  @HiveField(1)
  saavn,
}

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
  final MusicSource source;

  @HiveField(8)
  final String sourceId;

  @HiveField(9)
  final bool isDownloaded;

  @HiveField(10)
  final String? localPath;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.thumbnailUrl = '',
    this.audioUrl = '',
    this.durationMs = 0,
    this.source = MusicSource.youtube,
    this.sourceId = '',
    this.isDownloaded = false,
    this.localPath,
  });

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    String? audioUrl,
    int? durationMs,
    MusicSource? source,
    String? sourceId,
    bool? isDownloaded,
    String? localPath,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationMs: durationMs ?? this.durationMs,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  String toString() => 'SongModel(title: $title, artist: $artist, source: $source)';
}
