// fahrt_anfrage_service.dart
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/user_service.dart';

class RideRequestService {
  final _anfrageService = AnfrageService();
  final _userService = UserService();

  Future<bool> sendRequest({
    required FahrtDaten fahrt,
    required int seats,
    String? message,
  }) async {
    final user = _userService.safeUser;

    // Schutz vor Mehrfachanfrage
    final existing = _anfrageService
        .getAnfragenForFahrt(fahrt.id)
        .any((a) => a.requesterId == user.id);

    if (existing) return false;

    final anfrage = AnfrageDaten.create(
      fahrtId: fahrt.id,
      eventId: fahrt.eventId,
      requesterId: user.id,
      requesterName: user.name,
      seatsRequested: seats,
      fahrtOwnerId: fahrt.ownerId,
      eventName: fahrt.eventName,
      startOrt: fahrt.abfahrtsort,
      zielOrt: fahrt.standort,
      fahrerName: fahrt.ownerName,
      message: message,
    );

    await _anfrageService.addAnfrage(anfrage);
    return true;
  }
}
