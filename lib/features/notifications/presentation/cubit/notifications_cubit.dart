// Presentation: منطق الإشعارات — بيفلتر الإشعارات حسب المستخدم الحالي (مستخدم / أدمن / مالك)،
// بيحسب غير المقروء، وبيعرض الإشعار في شريط إشعارات التليفون.
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../account/domain/entities/user_profile.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/services/system_notifier.dart';

class NotificationsState {
  final List<AppNotification> items; // الأحدث أولًا — الخاصة بالمستخدم الحالي فقط
  const NotificationsState({this.items = const []});

  int get unread => items.where((n) => !n.read).length;
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;
  final SystemNotifier _notifier;
  final AccountRepository _account;

  UserProfile? _viewer;
  bool _permissionAsked = false;

  /// اللي اتعرض في إشعارات التليفون لكل مستخدم (عشان مايتكررش)
  final Set<String> _delivered = {};
  StreamSubscription<AppNotification>? _publishedSub;
  StreamSubscription<void>? _changesSub;

  NotificationsCubit({
    required NotificationsRepository repository,
    required SystemNotifier notifier,
    required AccountRepository account,
  })  : _repository = repository,
        _notifier = notifier,
        _account = account,
        super(const NotificationsState()) {
    _publishedSub = _repository.published.listen(_onPublished);
    _changesSub = _repository.changes.listen((_) => _refresh());
  }

  String get _viewerKey => '${_viewer?.email}|${_viewer?.phone}';

  /// بيتنادى بعد تسجيل الدخول / الخروج / فتح التطبيق (الدخول التلقائي)
  Future<void> syncViewer() async {
    UserProfile? profile;
    try {
      profile = await _account.getProfile();
    } catch (_) {
      profile = null;
    }
    if (isClosed) return;
    _viewer = profile;
    await _repository.sync(
      signedIn: profile != null,
      fast: profile != null && profile.role != UserRole.user,
    );
    if (isClosed) return;
    _refresh();
    if (profile == null) return;

    if (!_permissionAsked) {
      _permissionAsked = true;
      await _notifier.requestPermission();
    }
    // إشعارات وصلت وهو مش مسجّل دخول: تظهر دلوقتي في إشعارات التليفون
    for (final n in state.items.reversed) {
      if (!n.read) _deliver(n);
    }
  }

  void _onPublished(AppNotification n) {
    if (_repository.serverFiltered || n.isFor(_viewer)) _deliver(n);
  }

  void _deliver(AppNotification n) {
    if (_delivered.add('$_viewerKey#${n.id}')) {
      _notifier.show(n);
    }
  }

  void _refresh() {
    if (isClosed) return;
    emit(NotificationsState(
      items: _repository.all
          .where((n) => _repository.serverFiltered ? _viewer != null : n.isFor(_viewer))
          .toList(),
    ));
  }

  void markRead(String id) => _repository.markRead([id]);

  void markAllRead() => _repository
      .markRead(state.items.where((n) => !n.read).map((n) => n.id));

  void remove(String id) => _repository.remove([id]);

  /// مسح كل إشعارات المستخدم الحالي بس (مش بتاعت غيره)
  void clearAll() => _repository.remove(state.items.map((n) => n.id));

  @override
  Future<void> close() {
    _publishedSub?.cancel();
    _changesSub?.cancel();
    return super.close();
  }
}
