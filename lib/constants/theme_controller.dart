import 'package:flutter/material.dart';

/// التحكم في الوضع (فاتح / داكن) للتطبيق كله.
///
/// الألوان نفسها معرّفة في [AppColors] (ليها نسخة فاتحة ونسخة داكنة مصممة لوحدها)،
/// والـ ThemeController بس بيقلب الوضع وبيطلب من Flutter يعيد رسم الشاشات.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  bool _dark = false;
  bool get isDark => _dark;

  void toggle() => setDark(!_dark);

  void setDark(bool value) {
    if (_dark == value) return;
    _dark = value;
    notifyListeners();
    // ألوان AppColors بتتقرا وقت الـ build، فلازم نخلّي كل الـ widgets تتبني
    // من جديد (حتى الـ const widgets) عشان تاخد الألوان الجديدة.
    _rebuildAll();
  }

  static void _rebuildAll() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    root.visitChildren(rebuild);
  }

  /// لوجو التطبيق حسب الوضع (فاتح + داكن: png)
  static String get logoAsset => instance.isDark
      ? 'assets/images/cary_logo_dark.png'
      : 'assets/images/cary_logo.png';

  /// لون الستارة اللي ورا النوافذ والـ bottom sheets
  static Color get barrierColor =>
      instance.isDark ? Colors.black87 : Colors.black54;
}
