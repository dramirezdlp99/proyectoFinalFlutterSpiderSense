// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetectionRecordAdapter extends TypeAdapter<DetectionRecord> {
  @override
  final int typeId = 0;

  @override
  DetectionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectionRecord(
      label: fields[0] as String,
      labelEs: fields[1] as String,
      confidence: fields[2] as double,
      detectedAt: fields[3] as DateTime,
      isDangerous: fields[6] as bool,
      userId: fields[7] as String,
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, DetectionRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.labelEs)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.detectedAt)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.isDangerous)
      ..writeByte(7)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
