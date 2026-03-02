// lib/data/hive_anfrage_repository.dart
import 'package:hive/hive.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/interfaces/i_anfrage_repository.dart';

class HiveAnfrageRepository implements IAnfrageRepository {
  final Box<AnfrageDaten> _box;

  HiveAnfrageRepository(this._box);

  @override
  List<AnfrageDaten> getAll() => _box.values.toList();

  @override
  Future<void> add(AnfrageDaten anfrage) async {
    await _box.put(anfrage.id, anfrage);
  }

  @override
  Future<void> update(AnfrageDaten anfrage) async {
    await _box.put(anfrage.id, anfrage);
  }

  @override
  Future<void> reload() async {
    // Hive ist lokal — keine Netzwerkoperation nötig
  }
}
