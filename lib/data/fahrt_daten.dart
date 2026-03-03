// lib/data/fahrt_daten.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'fahrt_daten.g.dart';

@HiveType(typeId: 1)
enum Fahrtrichtung {
  @HiveField(0)
  hinfahrt,
  @HiveField(1)
  rueckfahrt,
  @HiveField(2)
  hinUndZurueck,
}

@HiveType(typeId: 2)
class FahrtDaten {
  @HiveField(0)
  final String eventId;

  @HiveField(1)
  final String eventName;

  @HiveField(2)
  final String standort;

  @HiveField(3)
  final String abfahrtsort;

  // Uhrzeit intern als separate hour/min ints -> einfach serialisierbar
  @HiveField(4)
  final int uhrzeitHour;

  @HiveField(5)
  final int uhrzeitMinute;

  @HiveField(6)
  final int? rueckuhrzeitHour;

  @HiveField(7)
  final int? rueckuhrzeitMinute;

  @HiveField(8)
  final int freiePlaetze;

  @HiveField(9)
  final Fahrtrichtung richtung;

  @HiveField(10)
  final String ownerId;

  @HiveField(11)
  final String ownerName;

  // Eindeutige, stabile ID (final)
  @HiveField(12)
  final String id;

  @HiveField(13)
  final double? abfahrtsortLat;

  @HiveField(14)
  final double? abfahrtsortLng;

  @HiveField(15)
  final String? abfahrtsortFullAddress;

  FahrtDaten({
    required this.eventId,
    required this.eventName,
    required this.standort,
    required this.abfahrtsort,
    required this.uhrzeitHour,
    required this.uhrzeitMinute,
    required this.rueckuhrzeitHour,
    required this.rueckuhrzeitMinute,
    required this.freiePlaetze,
    required this.richtung,
    required this.ownerId,
    required this.ownerName,
    required this.id,
    this.abfahrtsortLat,
    this.abfahrtsortLng,
    this.abfahrtsortFullAddress,
  });

  factory FahrtDaten.fromTimeOfDay({
    required String eventId,
    required String eventName,
    required String standort,
    required String abfahrtsort,
    required TimeOfDay uhrzeit,
    TimeOfDay? rueckuhrzeit,
    required int freiePlaetze,
    required Fahrtrichtung richtung,
    required String ownerId,
    required String ownerName,
    String? id,
    double? abfahrtsortLat,
    double? abfahrtsortLng,
    String? abfahrtsortFullAddress,
  }) {
    return FahrtDaten(
      eventId: eventId,
      eventName: eventName,
      standort: standort,
      abfahrtsort: abfahrtsort,
      uhrzeitHour: uhrzeit.hour,
      uhrzeitMinute: uhrzeit.minute,
      rueckuhrzeitHour: rueckuhrzeit?.hour,
      rueckuhrzeitMinute: rueckuhrzeit?.minute,
      freiePlaetze: freiePlaetze,
      richtung: richtung,
      ownerId: ownerId,
      ownerName: ownerName,
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      abfahrtsortLat: abfahrtsortLat,
      abfahrtsortLng: abfahrtsortLng,
      abfahrtsortFullAddress: abfahrtsortFullAddress,
    );
  }

  TimeOfDay get uhrzeit => TimeOfDay(hour: uhrzeitHour, minute: uhrzeitMinute);

  TimeOfDay? get rueckuhrzeit {
    if (rueckuhrzeitHour == null || rueckuhrzeitMinute == null) return null;
    return TimeOfDay(hour: rueckuhrzeitHour!, minute: rueckuhrzeitMinute!);
  }

  // Kurzform für Anzeige (nur Text vor dem ersten Komma)
  String get abfahrtsortAnzeige => abfahrtsort.split(',').first.trim();

  // kompatible Getter
  String get startOrt => abfahrtsort;
  String get zielOrt => standort;
  int get plaetze => freiePlaetze;
  String get anbieter => ownerName;
  String get stabileId => eventId;

  FahrtDaten copyWith({
    String? eventId,
    String? eventName,
    String? standort,
    String? abfahrtsort,
    int? uhrzeitHour,
    int? uhrzeitMinute,
    int? rueckuhrzeitHour,
    int? rueckuhrzeitMinute,
    int? freiePlaetze,
    Fahrtrichtung? richtung,
    String? ownerId,
    String? ownerName,
    String? id,
    double? abfahrtsortLat,
    double? abfahrtsortLng,
    String? abfahrtsortFullAddress,
  }) {
    return FahrtDaten(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      standort: standort ?? this.standort,
      abfahrtsort: abfahrtsort ?? this.abfahrtsort,
      uhrzeitHour: uhrzeitHour ?? this.uhrzeitHour,
      uhrzeitMinute: uhrzeitMinute ?? this.uhrzeitMinute,
      rueckuhrzeitHour: rueckuhrzeitHour ?? this.rueckuhrzeitHour,
      rueckuhrzeitMinute: rueckuhrzeitMinute ?? this.rueckuhrzeitMinute,
      freiePlaetze: freiePlaetze ?? this.freiePlaetze,
      richtung: richtung ?? this.richtung,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      id: id ?? this.id,
      abfahrtsortLat: abfahrtsortLat ?? this.abfahrtsortLat,
      abfahrtsortLng: abfahrtsortLng ?? this.abfahrtsortLng,
      abfahrtsortFullAddress: abfahrtsortFullAddress ?? this.abfahrtsortFullAddress,
    );
  }

  /// Serialisierung (für Firestore/JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'standort': standort,
      'abfahrtsort': abfahrtsort,
      'uhrzeitHour': uhrzeitHour,
      'uhrzeitMinute': uhrzeitMinute,
      'rueckuhrzeitHour': rueckuhrzeitHour,
      'rueckuhrzeitMinute': rueckuhrzeitMinute,
      'freiePlaetze': freiePlaetze,
      'richtung': richtung.index, // store enum as int
      'ownerId': ownerId,
      'ownerName': ownerName,
      'abfahrtsortLat': abfahrtsortLat,
      'abfahrtsortLng': abfahrtsortLng,
      'abfahrtsortFullAddress': abfahrtsortFullAddress,
    };
  }

  factory FahrtDaten.fromMap(Map<String, dynamic> map) {
    // defensive parsing
    int parseInt(dynamic v, [int defaultValue = 0]) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? defaultValue;
      return defaultValue;
    }

    final richtungIndex = parseInt(map['richtung'], 0);
    final richtung = Fahrtrichtung.values
        .elementAt(richtungIndex.clamp(0, Fahrtrichtung.values.length - 1));

    return FahrtDaten(
      eventId: map['eventId'] as String? ?? '',
      eventName: map['eventName'] as String? ?? '',
      standort: map['standort'] as String? ?? '',
      abfahrtsort: map['abfahrtsort'] as String? ?? '',
      uhrzeitHour: parseInt(map['uhrzeitHour']),
      uhrzeitMinute: parseInt(map['uhrzeitMinute']),
      rueckuhrzeitHour:
          map.containsKey('rueckuhrzeitHour') ? parseInt(map['rueckuhrzeitHour'], null as int? ?? 0) : null,
      // if absent, keep null
      rueckuhrzeitMinute: map.containsKey('rueckuhrzeitMinute')
          ? parseInt(map['rueckuhrzeitMinute'], null as int? ?? 0)
          : null,
      freiePlaetze: parseInt(map['freiePlaetze'], 0),
      richtung: richtung,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      abfahrtsortLat: (map['abfahrtsortLat'] as num?)?.toDouble(),
      abfahrtsortLng: (map['abfahrtsortLng'] as num?)?.toDouble(),
      abfahrtsortFullAddress: map['abfahrtsortFullAddress'] as String?,
    );
  }

  String toJsonString() => toMap().toString();
}
