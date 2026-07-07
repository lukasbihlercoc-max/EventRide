/// Standard-Timeout für Firestore-Schreib-/Lesevorgänge in UI-Handlern.
/// Verhindert, dass ein hängender Future (schlechte Verbindung + aktivierte
/// Offline-Persistenz) eine Ladeanzeige für immer anzeigt.
const kDefaultAsyncTimeout = Duration(seconds: 15);

/// Wird geworfen wenn [guarded] durch den Timeout abgebrochen wurde,
/// damit Call-Sites gezielt zwischen Timeout und echtem Fehler unterscheiden
/// können (z.B. anderes UX-Verhalten bei "Verbindung langsam" vs. Fehler).
class AsyncGuardTimeoutException implements Exception {
  const AsyncGuardTimeoutException();

  @override
  String toString() => 'Zeitüberschreitung – Verbindung zu langsam';
}

/// Wrappt [future] mit einem Timeout (Standard: 15s, pro Aufruf überschreibbar).
/// Wirft [AsyncGuardTimeoutException] statt eines rohen TimeoutException.
Future<T> guarded<T>(
  Future<T> future, {
  Duration timeout = kDefaultAsyncTimeout,
}) {
  return future.timeout(
    timeout,
    onTimeout: () => throw const AsyncGuardTimeoutException(),
  );
}
