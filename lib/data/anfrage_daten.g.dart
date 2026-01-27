// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anfrage_daten.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnfrageDatenAdapter extends TypeAdapter<AnfrageDaten> {
  @override
  final int typeId = 4;

  @override
  AnfrageDaten read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnfrageDaten(
      id: fields[0] as String,
      fahrtId: fields[1] as String,
      eventId: fields[2] as String,
      requesterId: fields[3] as String,
      requesterName: fields[4] as String,
      seatsRequested: fields[5] as int,
      status: fields[6] as AnfrageStatus,
      createdAt: fields[7] as DateTime,
      fahrtOwnerId: fields[9] as String,
      message: fields[8] as String?,
      seatsAccepted: fields[10] as int?,
      eventName: fields[11] as String,
      startOrt: fields[12] as String,
      zielOrt: fields[13] as String,
      fahrerName: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AnfrageDaten obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fahrtId)
      ..writeByte(2)
      ..write(obj.eventId)
      ..writeByte(3)
      ..write(obj.requesterId)
      ..writeByte(4)
      ..write(obj.requesterName)
      ..writeByte(5)
      ..write(obj.seatsRequested)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.message)
      ..writeByte(9)
      ..write(obj.fahrtOwnerId)
      ..writeByte(10)
      ..write(obj.seatsAccepted)
      ..writeByte(11)
      ..write(obj.eventName)
      ..writeByte(12)
      ..write(obj.startOrt)
      ..writeByte(13)
      ..write(obj.zielOrt)
      ..writeByte(14)
      ..write(obj.fahrerName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnfrageDatenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnfrageStatusAdapter extends TypeAdapter<AnfrageStatus> {
  @override
  final int typeId = 3;

  @override
  AnfrageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnfrageStatus.offen;
      case 1:
        return AnfrageStatus.akzeptiert;
      case 2:
        return AnfrageStatus.abgelehnt;
      default:
        return AnfrageStatus.offen;
    }
  }

  @override
  void write(BinaryWriter writer, AnfrageStatus obj) {
    switch (obj) {
      case AnfrageStatus.offen:
        writer.writeByte(0);
        break;
      case AnfrageStatus.akzeptiert:
        writer.writeByte(1);
        break;
      case AnfrageStatus.abgelehnt:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnfrageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
