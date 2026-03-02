// fahrt_repository.dart

import 'package:hive/hive.dart';
import 'fahrt_daten.dart';
import 'interfaces/i_fahrt_repository.dart';

class FahrtRepository implements IFahrtRepository {
  final Box<FahrtDaten> _box;

  FahrtRepository(this._box);

  @override
  List<FahrtDaten> getAll() {
    return _box.values.toList();
  }

  @override
  Future<void> add(FahrtDaten fahrt) async {
    await _box.put(fahrt.id, fahrt);
  }

  @override
  Future<void> update(FahrtDaten fahrt) async {
    await _box.put(fahrt.id, fahrt);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
