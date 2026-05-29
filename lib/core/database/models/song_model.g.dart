
part of 'song_model.dart';


class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongModel(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      thumbnailUrl: fields[4] as String,
      audioUrl: fields[5] as String,
      durationMs: fields[6] as int,
      source: fields[7] as MusicSource,
      sourceId: fields[8] as String,
      isDownloaded: fields[9] as bool,
      localPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.audioUrl)
      ..writeByte(6)
      ..write(obj.durationMs)
      ..writeByte(7)
      ..write(obj.source)
      ..writeByte(8)
      ..write(obj.sourceId)
      ..writeByte(9)
      ..write(obj.isDownloaded)
      ..writeByte(10)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MusicSourceAdapter extends TypeAdapter<MusicSource> {
  @override
  final int typeId = 4;

  @override
  MusicSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MusicSource.youtube;
      case 1:
        return MusicSource.saavn;
      default:
        return MusicSource.youtube;
    }
  }

  @override
  void write(BinaryWriter writer, MusicSource obj) {
    switch (obj) {
      case MusicSource.youtube:
        writer.writeByte(0);
        break;
      case MusicSource.saavn:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
