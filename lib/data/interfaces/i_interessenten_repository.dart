// lib/data/interfaces/i_interessenten_repository.dart
import 'package:my_app/data/interessenten_daten.dart';

abstract class IInteressentenRepository {
  /// Echtzeit-Stream aller Interessenten für ein Event.
  Stream<List<InteressentenDaten>> watchForEvent(String eventId);

  /// Gibt den Interessenten-Eintrag zurück falls vorhanden.
  Future<InteressentenDaten?> get(String id);

  /// Fügt den aktuellen User als Interessenten hinzu.
  Future<void> add(InteressentenDaten interessent);

  /// Entfernt den Interessenten-Eintrag.
  Future<void> remove(String id);
}
