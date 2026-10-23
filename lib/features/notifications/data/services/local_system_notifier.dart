// Data: إشعارات التليفون عن طريق flutter_local_notifications (أندرويد + iOS).
// ملاحظة: الحزمة دي بتعرض إشعارات "محلية" من التطبيق نفسه. لوصول إشعار والتطبيق
// مقفول تمامًا من جهاز تاني لازم Push من السيرفر (FCM/APNs) — شوف الملاحظات في التسليم.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/services/system_notifier.dart';

class LocalSystemNotifier implements SystemNotifier {
  static const String _channelId = 'cary_general';

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _nextId = 0;
  void Function(String? payload)? _onTap;

  @override
  set onTap(void Function(String? payload)? callback) => _onTap = callback;

  @override
  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (r) => _onTap?.call(r.payload),
      );
      _ready = true;
    } catch (_) {
      _ready = false; // منصة مش مدعومة (ويب / ديسكتوب): التطبيق بيكمل عادي
    }
  }

  @override
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  @override
  Future<void> show(AppNotification notification) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'إشعارات CARY',
        channelDescription: 'إشعارات الإعلانات والحجوزات وآراء العملاء',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    try {
      await _plugin.show(
        id: _nextId++,
        title: notification.title,
        body: notification.body,
        notificationDetails: details,
        payload: notification.type.name,
      );
    } catch (_) {}
  }
}