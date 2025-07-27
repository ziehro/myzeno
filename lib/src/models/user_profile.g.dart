// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      startWeight: fields[0] as double,
      height: fields[1] as double,
      age: fields[2] as int,
      sex: fields[3] as Sex,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.startWeight)
      ..writeByte(1)
      ..write(obj.height)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.sex)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SexAdapter extends TypeAdapter<Sex> {
  @override
  final int typeId = 100;

  @override
  Sex read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Sex.male;
      case 1:
        return Sex.female;
      default:
        return Sex.male;
    }
  }

  @override
  void write(BinaryWriter writer, Sex obj) {
    switch (obj) {
      case Sex.male:
        writer.writeByte(0);
        break;
      case Sex.female:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SexAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
