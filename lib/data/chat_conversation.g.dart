// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatConversationAdapter extends TypeAdapter<ChatConversation> {
  @override
  final int typeId = 41;

  @override
  ChatConversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatConversation(
      id: fields[0] as String,
      fahrtId: fields[1] as String,
      ownerId: fields[2] as String,
      requesterId: fields[3] as String,
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatConversation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fahrtId)
      ..writeByte(2)
      ..write(obj.ownerId)
      ..writeByte(3)
      ..write(obj.requesterId)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
