// Data: تخزين الإشعارات في الذاكرة (زي باقي الداتا التجريبية).
import 'dart:async';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class InMemoryNotificationsRepository implements NotificationsRepository {
  static const int _max = 200;

  final List<AppNotification> _items = [];
  final StreamController<AppNotification> _published =
      StreamController<AppNotification>.broadcast();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  List<AppNotification> get all => List.unmodifiable(_items);

  @override
  Stream<AppNotification> get published => _published.stream;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  bool get serverFiltered => false;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> sync({required bool signedIn, bool fast = false}) async {}

  @override
  void publish(AppNotification notification) {
    _items.insert(0, notification);
    if (_items.length > _max) _items.removeRange(_max, _items.length);
    _published.add(notification);
    _changes.add(null);
  }

  @override
  void markRead(Iterable<String> ids) {
    final set = ids.toSet();
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (set.contains(_items[i].id) && !_items[i].read) {
        _items[i] = _items[i].copyWith(read: true);
        changed = true;
      }
    }
    if (changed) _changes.add(null);
  }

  @override
  void remove(Iterable<String> ids) {
    final set = ids.toSet();
    final before = _items.length;
    _items.removeWhere((n) => set.contains(n.id));
    if (_items.length != before) _changes.add(null);
  }
}
