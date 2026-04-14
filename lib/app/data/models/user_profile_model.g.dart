// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 3;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      businessName: fields[0] as String,
      address: fields[1] as String,
      email: fields[2] as String,
      phone: fields[3] as String,
      gstin: fields[4] as String?,
      logoPath: fields[5] as String?,
      defaultGstRate: fields[6] as double,
      defaultTerms: fields[7] as String,
      defaultNotes: fields[8] as String,
      googleDisplayName: fields[9] as String?,
      googlePhotoUrl: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.gstin)
      ..writeByte(5)
      ..write(obj.logoPath)
      ..writeByte(6)
      ..write(obj.defaultGstRate)
      ..writeByte(7)
      ..write(obj.defaultTerms)
      ..writeByte(8)
      ..write(obj.defaultNotes)
      ..writeByte(9)
      ..write(obj.googleDisplayName)
      ..writeByte(10)
      ..write(obj.googlePhotoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
