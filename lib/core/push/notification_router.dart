// Core: توجيه الضغط على الإشعار للشاشة المناسبة.
//   newBooking  -> إدارة الحجوزات
//   newAd       -> إدارة الإعلانات
//   newFeedback -> آراء العملاء
//   غير كده     -> شاشة الإشعارات
// لو التطبيق اتفتح من الإشعار والمستخدم لسه ما وصلش للشاشة الرئيسية، الطلب بيتحفظ لحد ما تتفتح.
class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  void Function(String? type)? _handler;
  bool _hasPending = false;
  String? _pendingType;

  void open(String? type) {
    final h = _handler;
    if (h != null) {
      h(type);
    } else {
      _hasPending = true;
      _pendingType = type;
    }
  }

  /// بتتنادى من الشاشة الرئيسية (اللي تحتها الـ Providers اللازمة)
  void attach(void Function(String? type) handler) {
    _handler = handler;
    if (_hasPending) {
      final t = _pendingType;
      _hasPending = false;
      _pendingType = null;
      Future<void>.delayed(const Duration(milliseconds: 400), () => handler(t));
    }
  }

  void detach() => _handler = null;
}
