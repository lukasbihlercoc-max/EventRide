// lib/data/event_daten.dart
class Event {
  final String id; // 🔑 endgültige, unveränderliche ID
  final String name;
  final DateTime datum;
  final String? uhrzeit;
  final String standort;
  final String typ;
  final String beschreibung;
  final String adresse;
  final double? latitude;
  final double? longitude;

  /// Anzahl "Ich will hin"-Interessenten. Wird ausschließlich serverseitig
  /// per Cloud Function gepflegt (onInteressentCreated/-Deleted) — deshalb
  /// nicht in toMap(), damit Client-Updates den Zähler nie überschreiben.
  final int interessentenCount;

  /// Angepinnt: erscheint oben in der Liste, mit etwas mehr Abstand zu den
  /// restlichen Events.
  final bool pinned;

  /// true = Container-Karte eines mehrtägigen Events (nur Hülle, keine
  /// eigene Detailseite). Kind-Events (siehe [containerId]) sind
  /// vollständig eigenständige Events und haben isContainer=false.
  final bool isContainer;

  /// Gesetzt bei einem Kind-Event eines mehrtägigen Containers, zeigt auf
  /// die id des Container-Events. null = normales Event oder Container.
  final String? containerId;

  // optional: alias für alte Verwendung
  String get stabileId => id;

  Event({
    String? id,
    required this.name,
    required DateTime datum,
    this.uhrzeit,
    required this.standort,
    required this.beschreibung,
    required this.typ,
    required this.adresse,
    this.latitude,
    this.longitude,
    this.interessentenCount = 0,
    this.pinned = false,
    this.isContainer = false,
    this.containerId,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        // Normalisiere Datum auf UTC intern, damit Firestore-kompatibel
        datum = datum.toUtc();

  /// copyWith: sicher Felder ändern ohne ID zu verlieren
  Event copyWith({
    String? name,
    DateTime? datum,
    String? uhrzeit,
    String? standort,
    String? typ,
    String? beschreibung,
    String? adresse,
    double? latitude,
    double? longitude,
    bool? pinned,
    // id, isContainer, containerId bleiben absichtlich unverändert
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      datum: (datum ?? this.datum).toUtc(),
      uhrzeit: uhrzeit ?? this.uhrzeit,
      standort: standort ?? this.standort,
      beschreibung: beschreibung ?? this.beschreibung,
      typ: typ ?? this.typ,
      adresse: adresse ?? this.adresse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      interessentenCount: interessentenCount,
      pinned: pinned ?? this.pinned,
      isContainer: isContainer,
      containerId: containerId,
    );
  }

  /// Serialisierung für Firestore / JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // Datum als ISO8601 in UTC
      'datum': datum.toUtc().toIso8601String(),
      'uhrzeit': uhrzeit,
      'standort': standort,
      'typ': typ,
      'beschreibung': beschreibung,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'pinned': pinned,
      'isContainer': isContainer,
      'containerId': containerId,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    final rawDatum = map['datum'];
    DateTime parsedDatum;

    if (rawDatum is int) {
      parsedDatum = DateTime.fromMillisecondsSinceEpoch(rawDatum, isUtc: true);
    } else if (rawDatum is String) {
      // Handle DD.MM.YYYY (legacy manager format)
      final ddmmyyyy = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
      final m = ddmmyyyy.firstMatch(rawDatum);
      if (m != null) {
        parsedDatum = DateTime.utc(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
      } else {
        try {
          parsedDatum = DateTime.parse(rawDatum).toUtc();
        } catch (_) {
          parsedDatum = DateTime.now().toUtc();
        }
      }
    } else if (rawDatum is DateTime) {
      parsedDatum = rawDatum.toUtc();
    } else {
      parsedDatum = DateTime.now().toUtc();
    }

    return Event(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Unbenanntes Event',
      datum: parsedDatum,
      uhrzeit: map['uhrzeit'] as String?,
      standort: map['standort'] as String? ?? '',
      beschreibung: map['beschreibung'] as String? ?? '',
      typ: map['typ'] as String? ?? '',
      adresse: map['adresse'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      interessentenCount: (map['interessentenCount'] as num?)?.toInt() ?? 0,
      pinned: map['pinned'] as bool? ?? false,
      isContainer: map['isContainer'] as bool? ?? false,
      containerId: map['containerId'] as String?,
    );
  }

  /// Komfort: JSON-String (optional)
  String toJsonString() => toMap().toString();
}

/// Zeitpunkt, ab dem ein Event als "vorbei" gilt (lokale Zeit):
/// 6:00 Uhr des Tages nach dem Event-Datum.
/// Wird sowohl für die Event-Sichtbarkeit (FirestoreEventRepository.watch())
/// als auch für die Fahrt-Klassifizierung "vergangen" (fahrten_page.dart,
/// public_profile_page.dart) verwendet, damit beide konsistent sind.
DateTime eventHideAfter(DateTime eventDatum) {
  final local = eventDatum.toLocal();
  return DateTime(local.year, local.month, local.day + 1, 6, 0);
}
