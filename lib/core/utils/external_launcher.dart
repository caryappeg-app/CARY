// Core: فتح تطبيقات/روابط خارجية (واتساب...). الملف ده الوحيد المعتمد على url_launcher.
// الإضافة: flutter pub add url_launcher
import 'package:url_launcher/url_launcher.dart';

class ExternalLauncher {
  ExternalLauncher._();

  /// رقم محلي (01XXXXXXXXX) -> دولي (201XXXXXXXXX)
  static String toInternational(String phone, {String countryCode = '20'}) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith('0')) return '$countryCode${digits.substring(1)}';
    return digits;
  }

  /// بيفتح محادثة واتساب مع [phone] (ولو واتساب مش متسطّب بيفتح المتصفح).
  /// بيرجّع false لو فشل الفتح.
  static Future<bool> openWhatsApp(String phone, {String? message}) async {
    final number = toInternational(phone);
    if (number.isEmpty) return false;

    final text = (message == null || message.isEmpty)
        ? ''
        : '?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse('https://wa.me/$number$text');

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
