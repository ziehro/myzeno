// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserGoalAdapter extends TypeAdapter<UserGoal> {
  @override
  final int typeId = 0;

  @override
  UserGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserGoal(
      lbsToLose: fields[0] as double,
      days: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserGoal obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lbsToLose)
      ..writeByte(1)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
