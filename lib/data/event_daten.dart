// lib/data/event_daten.dart
class Event {
  final String id; // 🔑 endgültige, unveränderliche ID
  final String name;
  final DateTime datum;
  final String standort;
  final String typ;
  final String beschreibung;
  final String adresse;
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
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
    double? latitude,
    double? longitude,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
      'latitude': latitude,
      'longitude': longitude,
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
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  /// Komfort: JSON-String (optional)
  String toJsonString() => toMap().toString();
}
