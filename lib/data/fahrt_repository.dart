// fahrt_repository.dart

import 'package:hive/hive.dart';
import 'fahrt_daten.dart';

class FahrtRepository {
  final Box<FahrtDaten> _box;

  FahrtRepository(this._box);

  List<FahrtDaten> getAll() {
    return _box.values.toList();
  }

  Future<void> add(FahrtDaten fahrt) async {
    await _box.put(fahrt.id, fahrt);
  }

  Future<void> update(FahrtDaten fahrt) async {
    await _box.put(fahrt.id, fahrt);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
