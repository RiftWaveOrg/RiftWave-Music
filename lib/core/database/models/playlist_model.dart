import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<String> songIds;

  @HiveField(4)
  String thumbnailUrl;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    List<String>? songIds,
    this.thumbnailUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get songCount => songIds.length;

  @override
  String toString() => 'PlaylistModel(name: $name, songs: $songCount)';
}
