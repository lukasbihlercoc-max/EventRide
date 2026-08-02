// story_creator_config.dart
import 'package:flutter/animation.dart';

// Story Creator Mode — Standardwerte für die Timing-Einstellungen.
// Werden im Einstell-Dialog vor jeder Aufnahme angezeigt und können dort
// pro Session angepasst werden, um das beste Verhältnis zu finden.
//
// Ablauf: Startevent fokussieren (instant, ungefilmt) → Countdown →
// Pause → gefilmter Scroll Start→Ziel → Pause → Detailseite öffnen →
// Pause → Detailseite bis Ende scrollen.

/// Countdown-Overlay (z.B. "3…2…1"), bevor die gefilmte Bewegung beginnt.
const Duration kStoryCreatorDefaultCountdownDuration = Duration(milliseconds: 3000);

/// Stille Pause direkt nach dem Countdown, bevor der Scroll losläuft.
const Duration kStoryCreatorDefaultCountdownPauseDuration = Duration(milliseconds: 1500);

/// Gefilmte Bewegung: Scroll vom Start- zum Ziel-Event.
const Duration kStoryCreatorDefaultListScrollDuration = Duration(milliseconds: 900);

/// Pause nach Erreichen des Ziel-Events, bevor die Detailseite öffnet.
const Duration kStoryCreatorDefaultPauseDuration = Duration(milliseconds: 500);

/// Pause auf der Detailseite, bevor der Auto-Scroll zum Ende beginnt.
const Duration kStoryCreatorDefaultDetailPreScrollPauseDuration = Duration(milliseconds: 800);

/// Detailseite: Dauer des Scrolls bis zum Ende.
const Duration kStoryCreatorDefaultDetailScrollDuration = Duration(milliseconds: 3500);

// Event-Liste: schneller Start, sanftes Abbremsen zum Ende.
const Curve kStoryCreatorListScrollCurve = Curves.easeOutCubic;

// Detailseite: konstantes Tempo wirkt fürs Aufnehmen ruhiger als Easing.
const Curve kStoryCreatorDetailScrollCurve = Curves.linear;
