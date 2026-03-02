import 'package:my_app/data/fahrt_daten.dart';

abstract class IFahrtRepository {
  List<FahrtDaten> getAll();
  Stream<List<FahrtDaten>> watch();
  Future<void> add(FahrtDaten fahrt);
  Future<void> update(FahrtDaten fahrt);
  Future<void> delete(String id);
}
