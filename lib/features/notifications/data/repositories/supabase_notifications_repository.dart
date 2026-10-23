// Data: الإشعارات من Supabase.
// الداتابيز (triggers) هي اللي بتولّد الإشعار لما: يتضاف إعلان / يتبعت رأي / يتعمل حجز /
// الإعلان يتقبل أو يترفض / سيارة محجوزة تتباع. التطبيق بيسحبها كل 15 ثانية وهو شغّال،
// وأي إشعار جديد بيظهر في إشعارات التليفون.
// ملاحظة: وصول إشعار والتطبيق مقفول تمامًا محتاج Push أو خدمة خلفية — مش داخل هنا.
import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class SupabaseNotificationsRepository implements NotificationsRepository {

  /// المالك/الأدمن محتاجين إشعار سريع، والمستخدم العادي بيكفيه دقيقة (بيوفّر الداتا والسيرفر)
  static const Duration _fastPoll = Duration(seconds: 15);
  static const Duration _slowPoll = Duration(seconds: 60);

  /// كل كام دورة نسحب القايمة كاملة (عشان "مقروء/محذوف" من أجهزة تانية)
  static const int _fullEvery = 20;

  final ApiClient _client;
  SupabaseNotificationsRepository(this._client);

  List<AppNotification> _items = [];
  final Set<String> _known = {};
  final StreamController<AppNotification> _published =
      StreamController<AppNotification>.broadcast();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Timer? _timer;
  bool _signedIn = false;
  bool _busy = false;
  bool _firstLoad = true;
  DateTime? _newest; // أحدث إشعار وصلنا
  int _ticks = 0;

  @override
  List<AppNotification> get all => List.unmodifiable(_items);

  @override
  Stream<AppNotification> get published => _published.stream;

  @override
  Stream<void> get changes => _changes.stream;

  /// السيرفر بيرجّع إشعارات المستخدم الحالي بس (حسب الـ RLS والدور)
  @override
  bool get serverFiltered => true;

  @override
  Future<void> sync({required bool signedIn, bool fast = false}) async {
    _signedIn = signedIn;
    _timer?.cancel();
    _timer = null;
    if (!signedIn) {
      _items = [];
      _known.clear();
      _firstLoad = true;
      _newest = null;
      _ticks = 0;
      _changes.add(null);
      return;
    }
    await _fetch(full: true);
    _timer = Timer.periodic(fast ? _fastPoll : _slowPoll, (_) => _fetch());
  }

  @override
  Future<void> refresh() => _fetch();

  /// [full] = false: بنسحب الإشعارات الأحدث من آخر واحد وصلنا بس (رد صغير جدًا لو مفيش جديد)
  Future<void> _fetch({bool full = false}) async {
    if (_busy || !_signedIn) return;
    _busy = true;
    try {
      final incremental = !full &&
          !_firstLoad &&
          _newest != null &&
          (++_ticks % _fullEvery != 0);
      final json = await _client.post(
        '/rest/v1/rpc/my_notifications',
        body: incremental
            ? {'p_after': _newest!.toUtc().toIso8601String()}
            : const <String, dynamic>{},
      );
      if (json is! List || !_signedIn) return;
      final fresh = json
          .whereType<Map>()
          .map((m) => _parse(Map<String, dynamic>.from(m)))
          .whereType<AppNotification>()
          .toList();
      final isFirst = _firstLoad;
      final added = fresh.where((n) => !_known.contains(n.id)).toList();
      if (incremental) {
        // سحب تزايدي: نضيف الجديد بس على اللي عندنا
        if (added.isNotEmpty) {
          _known.addAll(added.map((n) => n.id));
          final merged = [...added, ..._items]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _items = merged.length > 200 ? merged.sublist(0, 200) : merged;
          _changes.add(null);
        }
      } else {
        _known
          ..clear()
          ..addAll(fresh.map((n) => n.id));
        _items = fresh;
        _changes.add(null);
      }
      _firstLoad = false;
      if (_items.isNotEmpty) _newest = _items.first.createdAt;
      // أول تحميل بيتعامل معاه الـ Cubit (غير المقروء بيظهر بعد الدخول)
      if (!isFirst) {
        for (final n in added.reversed) {
          if (!n.read) _published.add(n);
        }
      }
    } catch (_) {
      // مفيش نت / جلسة منتهية: نحاول تاني في الدورة الجاية
    } finally {
      _busy = false;
    }
  }

  static AppNotification? _parse(Map<String, dynamic> m) {
    final typeName = (m['type'] ?? '').toString();
    NotificationType? type;
    for (final t in NotificationType.values) {
      if (t.name == typeName) type = t;
    }
    if (type == null) return null;
    return AppNotification(
      id: (m['id'] ?? '').toString(),
      type: type,
      title: (m['title'] ?? '').toString(),
      body: (m['body'] ?? '').toString(),
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      recipient: m['staff'] == true
          ? const NotificationRecipient.staff()
          : const NotificationRecipient.user(),
      read: m['read'] == true,
    );
  }

  /// الإشعارات بتتولّد في الداتابيز، فمفيش حاجة تتنشر من التطبيق
  @override
  void publish(AppNotification notification) {}

  @override
  void markRead(Iterable<String> ids) {
    final set = ids.toSet();
    if (set.isEmpty) return;
    _items = [
      for (final n in _items) set.contains(n.id) ? n.copyWith(read: true) : n,
    ];
    _changes.add(null);
    _call('mark_notifications_read', set);
  }

  @override
  void remove(Iterable<String> ids) {
    final set = ids.toSet();
    if (set.isEmpty) return;
    _items = _items.where((n) => !set.contains(n.id)).toList();
    _changes.add(null);
    _call('hide_notifications', set);
  }

  void _call(String fn, Set<String> ids) {
    _client
        .post('/rest/v1/rpc/$fn', body: {'p_ids': ids.toList()})
        .catchError((_) {});
  }
}
