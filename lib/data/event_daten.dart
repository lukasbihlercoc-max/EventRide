// lib/data/event_daten.dart
import 'package:hive/hive.dart';

part 'event_daten.g.dart'; // wird automatisch generiert

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  final String id; // 🔑 endgültige, unveränderliche ID

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime datum;

  @HiveField(3)
  final String standort;

  @HiveField(4)
  final String typ;

  @HiveField(5)
  final String beschreibung;

  @HiveField(6)
  final String adresse;

  // optional: alias für alte Verwendung
  String get stabileId => id;

  Event({
    String? id,
    required this.name,
    required DateTime datum,
    required this.standort,
    required this.beschreibung,
    required this.typ,
    required this.adresse,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        // Normalisiere Datum auf UTC intern, damit Firestore-kompatibel
        datum = datum.toUtc();

  /// copyWith: sicher Felder ändern ohne ID zu verlieren
  Event copyWith({
    String? name,
    DateTime? datum,
    String? standort,
    String? typ,
    String? beschreibung,
    String? adresse,
    // id bleibt absichtlich unverändert
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      datum: (datum ?? this.datum).toUtc(),
      standort: standort ?? this.standort,
      beschreibung: beschreibung ?? this.beschreibung,
      typ: typ ?? this.typ,
      adresse: adresse ?? this.adresse,
    );
  }

  /// Serialisierung für Firestore / JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // Datum als ISO8601 in UTC
      'datum': datum.toUtc().toIso8601String(),
      'standort': standort,
      'typ': typ,
      'beschreibung': beschreibung,
      'adresse': adresse,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    final rawDatum = map['datum'];
    DateTime parsedDatum;

    if (rawDatum is int) {
      // fallback: epoch milliseconds
      parsedDatum = DateTime.fromMillisecondsSinceEpoch(rawDatum, isUtc: true);
    } else if (rawDatum is String) {
      parsedDatum = DateTime.parse(rawDatum).toUtc();
    } else if (rawDatum is DateTime) {
      parsedDatum = rawDatum.toUtc();
    } else {
      parsedDatum = DateTime.now().toUtc();
    }

    return Event(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Unbenanntes Event',
      datum: parsedDatum,
      standort: map['standort'] as String? ?? '',
      beschreibung: map['beschreibung'] as String? ?? '',
      typ: map['typ'] as String? ?? '',
      adresse: map['adresse'] as String? ?? '',
    );
  }

  /// Komfort: JSON-String (optional)
  String toJsonString() => toMap().toString();
}
