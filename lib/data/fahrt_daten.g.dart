// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fahrt_daten.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FahrtDatenAdapter extends TypeAdapter<FahrtDaten> {
  @override
  final int typeId = 2;

  @override
  FahrtDaten read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FahrtDaten(
      eventId: fields[0] as String,
      eventName: fields[1] as String,
      standort: fields[2] as String,
      abfahrtsort: fields[3] as String,
      uhrzeitHour: fields[4] as int,
      uhrzeitMinute: fields[5] as int,
      rueckuhrzeitHour: fields[6] as int?,
      rueckuhrzeitMinute: fields[7] as int?,
      freiePlaetze: fields[8] as int,
      richtung: fields[9] as Fahrtrichtung,
      ownerId: fields[10] as String,
      ownerName: fields[11] as String,
      id: fields[12] as String,
      abfahrtsortLat: fields[13] as double?,
      abfahrtsortLng: fields[14] as double?,
      abfahrtsortFullAddress: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FahrtDaten obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.eventName)
      ..writeByte(2)
      ..write(obj.standort)
      ..writeByte(3)
      ..write(obj.abfahrtsort)
      ..writeByte(4)
      ..write(obj.uhrzeitHour)
      ..writeByte(5)
      ..write(obj.uhrzeitMinute)
      ..writeByte(6)
      ..write(obj.rueckuhrzeitHour)
      ..writeByte(7)
      ..write(obj.rueckuhrzeitMinute)
      ..writeByte(8)
      ..write(obj.freiePlaetze)
      ..writeByte(9)
      ..write(obj.richtung)
      ..writeByte(10)
      ..write(obj.ownerId)
      ..writeByte(11)
      ..write(obj.ownerName)
      ..writeByte(12)
      ..write(obj.id)
      ..writeByte(13)
      ..write(obj.abfahrtsortLat)
      ..writeByte(14)
      ..write(obj.abfahrtsortLng)
      ..writeByte(15)
      ..write(obj.abfahrtsortFullAddress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FahrtDatenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FahrtrichtungAdapter extends TypeAdapter<Fahrtrichtung> {
  @override
  final int typeId = 1;

  @override
  Fahrtrichtung read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Fahrtrichtung.hinfahrt;
      case 1:
        return Fahrtrichtung.rueckfahrt;
      case 2:
        return Fahrtrichtung.hinUndZurueck;
      default:
        return Fahrtrichtung.hinfahrt;
    }
  }

  @override
  void write(BinaryWriter writer, Fahrtrichtung obj) {
    switch (obj) {
      case Fahrtrichtung.hinfahrt:
        writer.writeByte(0);
        break;
      case Fahrtrichtung.rueckfahrt:
        writer.writeByte(1);
        break;
      case Fahrtrichtung.hinUndZurueck:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FahrtrichtungAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
