// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodLogAdapter extends TypeAdapter<FoodLog> {
  @override
  final int typeId = 3;

  @override
  FoodLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodLog(
      name: fields[0] as String,
      calories: fields[1] as int,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
