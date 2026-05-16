import 'package:cloud_firestore/cloud_firestore.dart';

class EventRequest {
  final String id;
  final String uid;
  final String userName;
  final String? userPhotoUrl;
  final String submissionType; // 'manual' | 'flyer'
  final String status; // 'pending' | 'approved' | 'discarded'
  final DateTime submittedAt;

  // Manuelle Eingabe
  final String? eventName;
  final String? standort;
  final String? datum; // "dd.MM.yyyy"
  final String? eventTyp;
  final String? beschreibung;
  final String? adresse;
  final double? latitude;
  final double? longitude;

  // Flyer-Upload
  final String? flyerPath;
  final String? note;

  // Admin-Feedback
  final String? rejectReason;

  const EventRequest({
    required this.id,
    required this.uid,
    required this.userName,
    this.userPhotoUrl,
    required this.submissionType,
    required this.status,
    required this.submittedAt,
    this.eventName,
    this.standort,
    this.datum,
    this.eventTyp,
    this.beschreibung,
    this.adresse,
    this.latitude,
    this.longitude,
    this.flyerPath,
    this.note,
    this.rejectReason,
  });

  factory EventRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventRequest(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      userPhotoUrl: d['userPhotoUrl'] as String?,
      submissionType: d['submissionType'] as String? ?? 'manual',
      status: d['status'] as String? ?? 'pending',
      submittedAt:
          (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventName: d['eventName'] as String?,
      standort: d['standort'] as String?,
      datum: d['datum'] as String?,
      eventTyp: d['eventTyp'] as String?,
      beschreibung: d['beschreibung'] as String?,
      adresse: d['adresse'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      flyerPath: d['flyerPath'] as String?,
      note: d['note'] as String?,
      rejectReason: d['rejectReason'] as String?,
    );
  }
}
