import 'package:my_app/data/fahrt_daten.dart';

abstract class IFahrtRepository {
  List<FahrtDaten> getAll();
  Future<void> add(FahrtDaten fahrt);
  Future<void> update(FahrtDaten fahrt);
  Future<void> delete(String id);
}
