// fahrt_anfrage_service.dart
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_daten.dart';

class RideRequestService {
  final AnfrageService _anfrageService;

  RideRequestService(this._anfrageService);

  Future<bool> sendRequest({
    required FahrtDaten fahrt,
    required int seats,
    required String userId,
    required String userName,
    String? message,
  }) async {
    // Schutz vor Selbst-Anfrage und Mehrfachanfrage
    if (userId == fahrt.ownerId) return false;
    final existing = _anfrageService
        .getAnfragenForFahrt(fahrt.id)
        .any((a) => a.requesterId == userId);

    if (existing) return false;

    final anfrage = AnfrageDaten.create(
      fahrtId: fahrt.id,
      eventId: fahrt.eventId,
      requesterId: userId,
      requesterName: userName,
      seatsRequested: seats,
      fahrtOwnerId: fahrt.ownerId,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsort,
      zielOrt: fahrt.standort,
      fahrerName: fahrt.ownerName,
      message: message,
      eventDatum: fahrt.eventDatum,
    );

    await _anfrageService.addAnfrage(anfrage);
    return true;
  }
}
