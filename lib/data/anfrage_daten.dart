// anfrage_daten.dart

enum AnfrageStatus {
  offen,
  akzeptiert,
  abgelehnt,
  storniert,
}

class AnfrageDaten {
  final String id;          // eindeutige ID der Anfrage
  final String fahrtId;     // Verweis auf FahrtDaten.id
  final String eventId;     // optional, für schnellen Bezug
  final String requesterId; // User, der MITFAHREN möchte
  final String requesterName;
  final int seatsRequested;
  final AnfrageStatus status;
  final DateTime createdAt;
  final String? message;
  final String fahrtOwnerId; // 🔥 Fahrer der Fahrt
  final int? seatsAccepted; // Anzahl der akzeptierten Sitze
  final String eventName;
  final String startOrt;
  final String zielOrt;
  final String fahrerName;
  /// true = Fahrer hat den Gast eingeladen (umgekehrte Richtung)
  final bool vonFahrer;
  final DateTime updatedAt;

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
    this.vonFahrer = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

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
    bool vonFahrer = false,
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
      vonFahrer: vonFahrer,
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
      'vonFahrer': vonFahrer,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
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
      vonFahrer: map['vonFahrer'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
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
      vonFahrer: vonFahrer,
      updatedAt: status != null ? DateTime.now() : updatedAt,
    );
  }
}
