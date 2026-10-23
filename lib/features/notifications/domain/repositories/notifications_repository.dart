// Domain: عقد الإشعارات. لما الـ Backend يجهز: GET /notifications + Push (FCM) من السيرفر.
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  /// كل الإشعارات، الأحدث أولًا
  List<AppNotification> get all;

  /// بيطلع كل إشعار جديد لحظة نشره
  Stream<AppNotification> get published;

  /// بيطلع أي تغيير في القايمة (جديد / مقروء / مسح)
  Stream<void> get changes;

  /// true = السيرفر بيفلتر الإشعارات حسب المستخدم الحالي (مفيش داعي لفلترة محلية)
  bool get serverFiltered;

  /// تحديث الإشعارات من السيرفر بعد الدخول / الخروج (في الذاكرة: مفيش حاجة)
  /// [fast] = المالك/الأدمن (سحب أسرع)؛ المستخدم العادي بيكفيه سحب أبطأ
  Future<void> sync({required bool signedIn, bool fast = false});

  /// سحب الإشعارات الجديدة فورًا (بيتنادى لما يوصل Push والتطبيق مفتوح)
  Future<void> refresh();

  void publish(AppNotification notification);
  void markRead(Iterable<String> ids);
  void remove(Iterable<String> ids);
}
