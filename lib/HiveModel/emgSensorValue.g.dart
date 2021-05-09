// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emgSensorValue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmgSensorValueAdapter extends TypeAdapter<EmgSensorValue> {
  @override
  final int typeId = 0;

  @override
  EmgSensorValue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmgSensorValue(
      fields[0] as DateTime,
      fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, EmgSensorValue obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmgSensorValueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
