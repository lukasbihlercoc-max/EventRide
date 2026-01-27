import 'package:hive/hive.dart';
import 'event_daten.dart';

class EventRepository {
  final Box<Event> _box;

  EventRepository(this._box);

  List<Event> getAll() {
    return _box.values.toList();
  }

  Future<void> add(Event event) async {
    await _box.put(event.id, event);
  }

  Future<void> update(Event event) async {
    await _box.put(event.id, event);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
