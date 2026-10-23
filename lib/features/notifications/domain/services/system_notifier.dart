// Domain: عرض إشعار في شريط إشعارات التليفون (حتى لو التطبيق في الخلفية).
import '../entities/app_notification.dart';

abstract class SystemNotifier {
  /// بيتنادى لما المستخدم يضغط على إشعار التليفون
  /// payload = نوع الإشعار (newBooking / newAd / newFeedback ...)
  set onTap(void Function(String? payload)? callback);

  Future<void> init();

  /// طلب إذن الإشعارات (أندرويد 13+ و iOS)
  Future<void> requestPermission();

  Future<void> show(AppNotification notification);
}
