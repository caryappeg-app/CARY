// Core: تنظيف المدخلات والبيانات الجاية من برا (Dart صافي).
// بيتستخدم في: الـ Cubits (نص البحث) + الـ Models (بيانات السيرفر قبل ما تبقى Entity).

class InputSanitizer {
  InputSanitizer._();

  static final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');
  static final RegExp _htmlTags = RegExp(r'<[^>]*>');
  // أحرف غير مرئية / تلاعب باتجاه النص (Bidi override)
  static final RegExp _invisible =
      RegExp(r'[\u200B-\u200D\u2060\uFEFF\u202A-\u202E\u2066-\u2069]');
  static final RegExp _spaces = RegExp(r'\s+');

  /// نص حر: بيشيل الـ HTML والأحرف الخفية ويقصّ الطول
  static String text(Object? input, {int maxLength = 300}) {
    var s = (input ?? '').toString();
    s = s
        .replaceAll(_htmlTags, '')
        .replaceAll(_controlChars, ' ')
        .replaceAll(_invisible, '')
        .replaceAll(_spaces, ' ')
        .trim();
    return s.length > maxLength ? s.substring(0, maxLength) : s;
  }

  /// نص البحث (حد أقصى 60 حرف)
  static String searchQuery(String? input) => text(input, maxLength: 60);

  /// لو الـ Backend بيستخدم LIKE / ILIKE: بيهرّب الرموز الخاصة
  static String escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  /// مسار صورة آمن: assets أو https بس (بيرفض javascript: / file: / http: ويقبل مسار ملف محلي مطلق)
  static String safeImageRef(Object? input) {
    final s = (input ?? '').toString().trim();
    if (s.startsWith('assets/') || s.startsWith('https://')) return s;
    // رابط صورة مؤقت من الـ picker على الويب
    if (s.startsWith('blob:')) return s;
    // مسار صورة على الجهاز (صور إعلانات المستخدم): مطلق ومن غير '..'
    if (s.startsWith('/') && !s.contains('..')) return s;
    return '';
  }

  /// عدد صحيح غير سالب ضمن حدود
  static int nonNegativeInt(Object? v, {int max = 1000000000}) {
    final n = (v as num?)?.toInt() ?? 0;
    if (n < 0) return 0;
    return n > max ? max : n;
  }
}
