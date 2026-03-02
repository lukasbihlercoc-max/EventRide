import 'package:my_app/data/event_daten.dart';

abstract class IEventRepository {
  List<Event> getAll();
  Future<void> add(Event event);
  Future<void> update(Event event);
  Future<void> delete(String id);
}
