// Domain: رسالة "رأيك يهمنا" (شكوى / اقتراح / استفسار / تقييم) من المستخدم
import 'feedback_subject.dart';

class FeedbackEntry {
  /// معرّف الرأي على السيرفر (فاضي للرسايل اللي لسه بتتبعت)
  final String id;
  final FeedbackSubject subject;
  final String details;
  final String senderName;
  final String senderEmail;
  final String senderPhone;

  /// وقت الإرسال (بيتحط من السيرفر/الـ Mock، وبيظهر في آراء العملاء)
  final DateTime? createdAt;

  const FeedbackEntry({
    this.id = '',
    required this.subject,
    required this.details,
    this.senderName = '',
    this.senderEmail = '',
    this.senderPhone = '',
    this.createdAt,
  });
}
