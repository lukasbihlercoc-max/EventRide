import 'package:hive/hive.dart';
import 'event_daten.dart';
import 'interfaces/i_event_repository.dart';

class EventRepository implements IEventRepository {
  final Box<Event> _box;

  EventRepository(this._box);

  @override
  List<Event> getAll() {
    return _box.values.toList();
  }

  @override
  Future<void> add(Event event) async {
    await _box.put(event.id, event);
  }

  @override
  Future<void> update(Event event) async {
    await _box.put(event.id, event);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
