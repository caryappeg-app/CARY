// Domain: قواعد صلاحية الرسالة (بتتطبق قبل الإرسال)
import 'feedback_subject.dart';

class FeedbackRules {
  FeedbackRules._();

  static const int minDetails = 5;
  static const int maxDetails = 1000;

  /// بيرجّع رسالة الخطأ (بالعربي) أو null لو الرسالة سليمة
  static String? validate({
    required FeedbackSubject? subject,
    required String details,
  }) {
    if (subject == null) return 'من فضلك اختار الموضوع';
    final d = details.trim();
    if (d.isEmpty) return 'من فضلك اكتب التفاصيل';
    if (d.length < minDetails) return 'التفاصيل قصيرة جدًا';
    if (d.length > maxDetails) return 'التفاصيل طويلة جدًا';
    return null;
  }
}
