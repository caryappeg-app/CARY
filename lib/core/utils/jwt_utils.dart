// Core: قراءة تاريخ انتهاء الـ JWT محلياً (من غير أي طلب شبكة).
import 'dart:convert';

class JwtUtils {
  JwtUtils._();

  /// true لو التوكن JWT وخلص (مع هامش 30 ثانية).
  /// لو التوكن مش JWT (opaque) بنرجع false وبنسيب السيرفر يحكم (401 → Refresh).
  static bool isExpired(String token, {Duration leeway = const Duration(seconds: 30)}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! num) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiry.subtract(leeway));
    } catch (_) {
      return false;
    }
  }
}
