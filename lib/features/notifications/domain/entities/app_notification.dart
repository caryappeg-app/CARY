// Domain: إشعار داخل التطبيق (وبيتعرض كمان في إشعارات التليفون)
import '../../../account/domain/entities/user_profile.dart';

enum NotificationType {
  adApproved, // إعلاني اتقبل (تمت المراجعة)
  adRejected, // إعلاني اترفض
  carSold, // سيارة كنت حاجزها اتباعت
  newFeedback, // رأي جديد من عميل (أدمن / مالك)
  newAd, // إعلان جديد من مستخدم (أدمن / مالك)
  newBooking, // حجز جديد من مستخدم (أدمن / مالك)
}

/// مين المفروض يستلم الإشعار: كل الأدمن والمالك، أو مستخدم محدد (بالإيميل أو الهاتف)
class NotificationRecipient {
  final bool staff;
  final String email;
  final String phone;

  const NotificationRecipient.staff()
      : staff = true,
        email = '',
        phone = '';

  const NotificationRecipient.user({this.email = '', this.phone = ''})
      : staff = false;

  bool matches(UserProfile? p) {
    if (p == null) return false;
    if (staff) return p.role == UserRole.owner || p.role == UserRole.admin;
    final e = email.trim().toLowerCase();
    final ph = phone.trim();
    return (e.isNotEmpty && p.email.trim().toLowerCase() == e) ||
        (ph.isNotEmpty && p.phone.trim() == ph);
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationRecipient recipient;

  /// إيميل اللي عمل الحدث (مبنبلّغوش بحاجة هو عملها بنفسه)
  final String excludeEmail;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.recipient,
    this.excludeEmail = '',
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        recipient: recipient,
        excludeEmail: excludeEmail,
        read: read ?? this.read,
      );

  /// هل الإشعار ده يخص المستخدم الحالي؟
  bool isFor(UserProfile? p) {
    if (p == null || !recipient.matches(p)) return false;
    final ex = excludeEmail.trim().toLowerCase();
    return ex.isEmpty || p.email.trim().toLowerCase() != ex;
  }
}

/// الإشعارات الجاهزة لكل حدث في التطبيق (النصوص في مكان واحد)
class NotificationEvents {
  NotificationEvents._();

  static int _seq = 0;
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  static String _short(String s, [int max = 80]) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length > max ? '${t.substring(0, max)}...' : t;
  }

  static String _who(String name) => name.trim().isEmpty ? 'مستخدم' : name.trim();

  /// إعلان المستخدم اتقبل (من "قيد المراجعة" إلى "تم المراجعة")
  static AppNotification adApproved({
    required String carTitle,
    required String ownerEmail,
    required String ownerPhone,
  }) =>
      AppNotification(
        id: _newId(),
        type: NotificationType.adApproved,
        title: 'تمت مراجعة إعلانك',
        body: 'إعلان $carTitle اتقبل وبقى معروض للعملاء في الصفحة الرئيسية.',
        createdAt: DateTime.now(),
        recipient: NotificationRecipient.user(email: ownerEmail, phone: ownerPhone),
      );

  static AppNotification adRejected({
    required String carTitle,
    required String reason,
    required String ownerEmail,
    required String ownerPhone,
  }) =>
      AppNotification(
        id: _newId(),
        type: NotificationType.adRejected,
        title: 'تم رفض إعلانك',
        body: reason.trim().isEmpty
            ? 'إعلان $carTitle اترفض.'
            : 'إعلان $carTitle اترفض. السبب: ${_short(reason, 120)}',
        createdAt: DateTime.now(),
        recipient: NotificationRecipient.user(email: ownerEmail, phone: ownerPhone),
      );

  /// السيارة اتباعت لعميل تاني: بنوضّح ليه اختفت من "حجوزاتي"
  static AppNotification carSold({
    required String carTitle,
    required String buyerEmail,
    required String buyerPhone,
  }) =>
      AppNotification(
        id: _newId(),
        type: NotificationType.carSold,
        title: 'السيارة اتباعت',
        body: 'السيارة $carTitle اللي كنت حاجزها اتباعت لعميل تاني، '
            'ولذلك اتشالت من حجوزاتي.',
        createdAt: DateTime.now(),
        recipient: NotificationRecipient.user(email: buyerEmail, phone: buyerPhone),
      );

  static AppNotification newFeedback({
    required String subjectLabel,
    required String senderName,
    required String details,
    String senderEmail = '',
  }) =>
      AppNotification(
        id: _newId(),
        type: NotificationType.newFeedback,
        title: 'رأي جديد من عميل',
        body: '$subjectLabel من ${_who(senderName)}: ${_short(details)}',
        createdAt: DateTime.now(),
        recipient: const NotificationRecipient.staff(),
        excludeEmail: senderEmail,
      );

  static AppNotification newAd({
    required String carTitle,
    required String ownerName,
    String ownerEmail = '',
  }) =>
      AppNotification(
        id: _newId(),
        type: NotificationType.newAd,
        title: 'إعلان جديد قيد المراجعة',
        body: '${_who(ownerName)} أضاف إعلان $carTitle',
        createdAt: DateTime.now(),
        recipient: const NotificationRecipient.staff(),
        excludeEmail: ownerEmail,
      );

  static AppNotification newBooking({
    required String carTitle,
    required String buyerName,
    int? offerPrice,
    String buyerEmail = '',
  }) =>
      AppNotification(
        id: _newId(),
        type: NotificationType.newBooking,
        title: 'حجز جديد',
        body: '${_who(buyerName)} حجز $carTitle'
            '${offerPrice != null ? ' بعرض سعر $offerPrice جنيه' : ''}',
        createdAt: DateTime.now(),
        recipient: const NotificationRecipient.staff(),
        excludeEmail: buyerEmail,
      );
}
