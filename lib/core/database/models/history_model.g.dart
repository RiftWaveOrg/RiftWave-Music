
part of 'history_model.dart';


class HistoryModelAdapter extends TypeAdapter<HistoryModel> {
  @override
  final int typeId = 2;

  @override
  HistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryModel(
      songId: fields[0] as String,
      playedAt: fields[1] as DateTime?,
      playDurationMs: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.playedAt)
      ..writeByte(2)
      ..write(obj.playDurationMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
