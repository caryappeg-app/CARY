// Core: دوال تحقق جاهزة لـ `validator:` في الفورم (بترجّع رسالة خطأ أو null).
// نفس القواعد بتتستخدم في الـ Domain عشان الشاشة والداتا ما يختلفوش.
import 'input_sanitizer.dart';

class Validators {
  Validators._();

  static final RegExp _email =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');
  static final RegExp _egPhone = RegExp(r'^01[0125][0-9]{8}$');

  static String? requiredText(String? v, {String field = 'الحقل', int max = 200}) {
    final s = InputSanitizer.text(v, maxLength: max + 1);
    if (s.isEmpty) return 'من فضلك اكتب $field';
    if (s.length > max) return '$field طويل جدًا';
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'من فضلك اكتب البريد الإلكتروني';
    if (s.length > 254 || !_email.hasMatch(s)) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  /// رقم موبايل مصري: 01XXXXXXXXX
  static String? egyptianPhone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (s.isEmpty) return 'من فضلك اكتب رقم الموبايل';
    if (!_egPhone.hasMatch(s)) return 'رقم الموبايل غير صحيح';
    return null;
  }

  /// كلمة السر: 8 حروف على الأقل وفيها حرف ورقم
  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'من فضلك اكتب كلمة السر';
    if (s.length < 8) return 'كلمة السر لازم تكون 8 حروف على الأقل';
    if (!RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(s) ||
        !RegExp(r'[0-9]').hasMatch(s)) {
      return 'كلمة السر لازم تحتوي على حروف وأرقام';
    }
    return null;
  }

  static String? price(String? v, {int max = 100000000}) {
    final n = int.tryParse((v ?? '').replaceAll(',', '').trim());
    if (n == null) return 'اكتب السعر بالأرقام';
    if (n <= 0 || n > max) return 'السعر غير منطقي';
    return null;
  }

  static String? km(String? v) {
    final n = int.tryParse((v ?? '').replaceAll(',', '').trim());
    if (n == null) return 'اكتب الكيلومترات بالأرقام';
    if (n < 0 || n > 2000000) return 'قراءة العداد غير منطقية';
    return null;
  }

  static String? year(String? v, {int minYear = 1950}) {
    final n = int.tryParse((v ?? '').trim());
    final maxYear = DateTime.now().year + 1;
    if (n == null) return 'اكتب السنة بالأرقام';
    if (n < minYear || n > maxYear) return 'السنة غير صحيحة';
    return null;
  }
}
