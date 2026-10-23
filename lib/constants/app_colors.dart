import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// ألوان التطبيق: كل لون ليه نسخة فاتحة ونسخة داكنة، والاختيار بيتم تلقائي
/// حسب [ThemeController.isDark]. (مفيش `const` هنا لأن اللون بيتغير.)
class AppColors {
  AppColors._();

  static bool get isDark => ThemeController.instance.isDark;
  static Color _p(int light, int dark) => Color(isDark ? dark : light);

  // ---- أساسية
  static Color get navy => _p(0xFF1E3A8A, 0xFFA9C1FF);
  static Color get dark => _p(0xFF263242, 0xFF3A4B68); // زرار أساسي (نص أبيض)
  static Color get title => _p(0xFF111827, 0xFFF1F5F9);
  static Color get subtitle => _p(0xFF6B7280, 0xFF9AA7BD);
  static Color get hint => _p(0xFF9CA3AF, 0xFF7B889F);
  static Color get icon => _p(0xFF8A97AD, 0xFF8FA0BC);
  static Color get border => _p(0xFFD9DEE5, 0xFF33415C);
  static Color get checkbox => _p(0xFF0A6CFF, 0xFF4D8DFF);

  // ---- الأخطاء
  static Color get error => _p(0xFFDC2626, 0xFFF87171);
  static Color get errorBg => _p(0xFFFEE2E2, 0xFF3B1D24);
  static Color get errorBorder => _p(0xFFFCA5A5, 0xFF7F3A40);
  static Color get errorText => _p(0xFF991B1B, 0xFFFCA5A5);

  // ---- الصفحة الرئيسية
  static Color get pageBg => _p(0xFFF1F5FB, 0xFF0B1220);
  static Color get surface => _p(0xFFFFFFFF, 0xFF141D2F); // الكروت / الأبيض
  static Color get fieldFill => _p(0xFFF4F7FB, 0xFF1A2438);
  static Color get fieldBorder => _p(0xFFE2E8F0, 0xFF2A3650);
  static Color get blue => _p(0xFF0047CC, 0xFF3D7BFF);
  static Color get tileBg => _p(0xFFEFF4FF, 0xFF1B2A4A);
  static Color get badge => const Color(0xFFE11D48);

  // ---------------------------------------------------------------------------
  // ألوان "ثانوية" (حدود، خلفيات ملونة خفيفة، أخضر، أصفر...)
  // بتاخد قيمة اللون الفاتح وبترجّع اللون الفاتح نفسه، أو نظيره الداكن المصمم.
  // ---------------------------------------------------------------------------
  static Color tone(int light) {
    if (!isDark) return Color(light);
    final mapped = _darkTones[light];
    if (mapped != null) return Color(mapped);
    return _autoDark(Color(light));
  }

  /// نسخ داكنة مصممة يدوي لأكتر الألوان استخدامًا
  static const Map<int, int> _darkTones = {
    // أسطح خفيفة / حقول
    0xFFF1F5FB: 0xFF0B1220,
    0xFFF4F7FB: 0xFF1A2438,
    0xFFF8FAFC: 0xFF18223A,
    0xFFF7FAFF: 0xFF18223A,
    0xFFF9FBFE: 0xFF18223A,
    0xFFFAFBFD: 0xFF18223A,
    0xFFF7F9FC: 0xFF18223A,
    0xFFF6F8FB: 0xFF18223A,
    0xFFF1F4F9: 0xFF1D283C,
    0xFFF1F3F6: 0xFF1D283C,
    0xFFF1F6FF: 0xFF1B2A4A,
    0xFFE9EEF5: 0xFF212D44,
    0xFFE5EAF2: 0xFF1C2638,
    // حدود
    0xFFEDF1F6: 0xFF222E45,
    0xFFE8ECF2: 0xFF26324A,
    0xFFE3EAF3: 0xFF26324A,
    0xFFE5E9F0: 0xFF26324A,
    0xFFE2E8F0: 0xFF2A3650,
    0xFFDDE5EF: 0xFF2E3B56,
    0xFFDDE3EC: 0xFF2E3B56,
    0xFFD9DEE5: 0xFF33415C,
    0xFFD7DEE8: 0xFF33415C,
    0xFFD5DEE9: 0xFF33415C,
    0xFFCBD9EA: 0xFF38486A,
    0xFFC3CCD9: 0xFF3B4A66,
    // نصوص رمادية
    0xFF111827: 0xFFF1F5F9,
    0xFF6B7280: 0xFF9AA7BD,
    0xFF9CA3AF: 0xFF7B889F,
    0xFF94A3B8: 0xFF8695AD,
    0xFF8A97AD: 0xFF8FA0BC,
    0xFF263242: 0xFF3A4B68,
    0xFF1E3A8A: 0xFFA9C1FF,
    // أزرق
    0xFF0047CC: 0xFF3D7BFF,
    0xFF0A5CD6: 0xFF4D8DFF,
    0xFF0A6CFF: 0xFF4D8DFF,
    0xFF1E5AA8: 0xFF7DB0F5,
    0xFFEFF5FF: 0xFF1B2A4A,
    0xFFEFF4FF: 0xFF1B2A4A,
    0xFFC7DBF5: 0xFF2B4678,
    0xFF9CC3F0: 0xFF3B6AB0,
    // أخضر
    0xFFDCFCE7: 0xFF12301F,
    0xFFD9F8E8: 0xFF12301F,
    0xFFECFDF5: 0xFF12301F,
    0xFFA7E8C6: 0xFF1F5B3C,
    0xFF86EFAC: 0xFF1F5B3C,
    0xFF166534: 0xFF86EFAC,
    0xFF0B7A4B: 0xFF6EE7B0,
    0xFF16A34A: 0xFF22C55E,
    0xFF1FA35C: 0xFF22C55E,
    0xFF0E9F6E: 0xFF34D399,
    0xFF10B981: 0xFF34D399,
    // أصفر / برتقالي
    0xFFFFEFC2: 0xFF3A2E0F,
    0xFFFFF8E6: 0xFF332A12,
    0xFFF5DFA0: 0xFF6B5516,
    0xFF9A5B00: 0xFFF5C451,
    0xFFF5B800: 0xFFF5B800,
    0xFFD97706: 0xFFF59E0B,
    // أحمر
    0xFFFEE2E2: 0xFF3B1D24,
    0xFFFCA5A5: 0xFF7F3A40,
    0xFF991B1B: 0xFFFCA5A5,
    0xFFDC2626: 0xFFF87171,
    0xFFE11D48: 0xFFE11D48,
  };

  /// لو اللون مش في الجدول: بنعكس السطوع (HSL) بشكل لطيف
  static Color _autoDark(Color c) {
    final hsl = HSLColor.fromColor(c);
    final l = hsl.lightness;
    double nl;
    double ns = hsl.saturation;
    if (l >= 0.85) {
      nl = 0.10 + (1 - l) * 0.9; // أسطح فاتحة -> أسطح داكنة
      ns *= 0.6;
    } else if (l >= 0.6) {
      nl = 0.20 + (0.85 - l) * 0.5; // حدود -> حدود داكنة
      ns *= 0.6;
    } else if (l <= 0.4) {
      nl = 1 - l; // نصوص غامقة -> نصوص فاتحة
      ns *= 0.8;
    } else {
      nl = l;
    }
    return hsl.withLightness(nl.clamp(0.0, 1.0)).withSaturation(ns.clamp(0.0, 1.0)).toColor();
  }
}
