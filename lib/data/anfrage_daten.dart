// anfrage_daten.dart
import 'package:hive/hive.dart';

part 'anfrage_daten.g.dart';

@HiveType(typeId: 3)
enum AnfrageStatus {
  @HiveField(0)
  offen,
  @HiveField(1)
  akzeptiert,
  @HiveField(2)
  abgelehnt,
}

@HiveType(typeId: 4)
class AnfrageDaten {
  @HiveField(0)
  final String id;          // eindeutige ID der Anfrage

  @HiveField(1)
  final String fahrtId;     // Verweis auf FahrtDaten.id

  @HiveField(2)
  final String eventId;     // optional, für schnellen Bezug

  @HiveField(3)
  final String requesterId; // User, der MITFAHREN möchte

  @HiveField(4)
  final String requesterName;

  @HiveField(5)
  final int seatsRequested;

  @HiveField(6)
  final AnfrageStatus status;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final String? message;

  @HiveField(9)
  final String fahrtOwnerId; // 🔥 Fahrer der Fahrt

  @HiveField(10)
  final int? seatsAccepted; // Anzahl der akzeptierten Sitze

  @HiveField(11)
  final String eventName;

  @HiveField(12)
  final String startOrt;

  @HiveField(13)
  final String zielOrt;

  @HiveField(14)
  final String fahrerName;
  

  AnfrageDaten({
    required this.id,
    required this.fahrtId,
    required this.eventId,
    required this.requesterId,
    required this.requesterName,
    required this.seatsRequested,
    required this.status,
    required this.createdAt,
    required this.fahrtOwnerId,
    this.message,
    this.seatsAccepted,
    required this.eventName,
    required this.startOrt,
    required this.zielOrt,
    required this.fahrerName,
  });

  factory AnfrageDaten.create({
    required String fahrtId,
    required String eventId,
    required String requesterId,
    required String requesterName,
    required int seatsRequested,
    required String fahrtOwnerId,
    // 🔥 Snapshot-Daten
    required String eventName,
    required String startOrt,
    required String zielOrt,
    required String fahrerName,
    
    String? message,
  }) {
    return AnfrageDaten(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fahrtId: fahrtId,
      eventId: eventId,
      requesterId: requesterId,
      requesterName: requesterName,
      seatsRequested: seatsRequested,
      status: AnfrageStatus.offen,
      createdAt: DateTime.now(),
      fahrtOwnerId: fahrtOwnerId,
      message: message,
      seatsAccepted: null,
      eventName: eventName,
      startOrt: startOrt,
      zielOrt: zielOrt,
      fahrerName: fahrerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fahrtId': fahrtId,
      'eventId': eventId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'seatsRequested': seatsRequested,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'message': message,
      'fahrtOwnerId': fahrtOwnerId,
      'seatsAccepted': seatsAccepted,
      'eventName': eventName,
      'startOrt': startOrt,
      'zielOrt': zielOrt,
      'fahrerName': fahrerName,
    };
  }

  factory AnfrageDaten.fromMap(Map<String, dynamic> map) {
    final statusIndex = (map['status'] as int? ?? 0)
        .clamp(0, AnfrageStatus.values.length - 1);

    return AnfrageDaten(
      id: map['id'] as String? ?? '',
      fahrtId: map['fahrtId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? '',
      seatsRequested: map['seatsRequested'] as int? ?? 1,
      status: AnfrageStatus.values[statusIndex],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? 0),
      message: map['message'] as String?,
      fahrtOwnerId: map['fahrtOwnerId'] as String? ?? '',
      seatsAccepted: map['seatsAccepted'] as int?,
      eventName: map['eventName'] as String? ?? '',
      startOrt: map['startOrt'] as String? ?? '',
      zielOrt: map['zielOrt'] as String? ?? '',
      fahrerName: map['fahrerName'] as String? ?? '',
    );
  }

  AnfrageDaten copyWith({
    AnfrageStatus? status,
    int? seatsAccepted,
  }) {
    return AnfrageDaten(
      id: id,
      fahrtId: fahrtId,
      eventId: eventId,
      requesterId: requesterId,
      requesterName: requesterName,
      seatsRequested: seatsRequested,
      status: status ?? this.status,
      createdAt: createdAt,
      message: message,
      fahrtOwnerId: fahrtOwnerId,
      seatsAccepted: seatsAccepted ?? this.seatsAccepted,
      eventName: eventName,
      startOrt: startOrt,
      zielOrt: zielOrt,
      fahrerName: fahrerName,
    );
  }
}
