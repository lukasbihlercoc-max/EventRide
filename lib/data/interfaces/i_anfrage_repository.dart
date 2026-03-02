// lib/data/interfaces/i_anfrage_repository.dart
import 'package:my_app/data/anfrage_daten.dart';

abstract class IAnfrageRepository {
  List<AnfrageDaten> getAll();
  Stream<List<AnfrageDaten>> watch();
  Future<void> add(AnfrageDaten anfrage);
  Future<void> update(AnfrageDaten anfrage);
}
