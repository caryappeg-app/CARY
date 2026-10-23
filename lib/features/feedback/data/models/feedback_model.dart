// Data: موديل الرسالة — Entity <-> JSON (مع تنظيف النصوص قبل الإرسال وبعد الاستلام)
import '../../../../core/validation/input_sanitizer.dart';
import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/feedback_subject.dart';

class FeedbackModel {
  final String id;
  final String subject; // complaint | suggestion | inquiry | rating
  final String details;
  final String senderName;
  final String senderEmail;
  final String senderPhone;
  final DateTime? createdAt;

  const FeedbackModel({
    this.id = '',
    required this.subject,
    required this.details,
    required this.senderName,
    required this.senderEmail,
    required this.senderPhone,
    this.createdAt,
  });

  factory FeedbackModel.fromEntity(FeedbackEntry e) => FeedbackModel(
        subject: e.subject.name,
        details: InputSanitizer.text(e.details, maxLength: 1000),
        senderName: InputSanitizer.text(e.senderName, maxLength: 100),
        senderEmail: InputSanitizer.text(e.senderEmail, maxLength: 100),
        senderPhone: InputSanitizer.text(e.senderPhone, maxLength: 30),
      );

  /// بيتستخدم لما بنقرأ الآراء من السيرفر / الـ Mock (برضه بنظّف النصوص)
  factory FeedbackModel.fromJson(Map<String, dynamic> j) => FeedbackModel(
        id: InputSanitizer.text(j['id'], maxLength: 64),
        subject: InputSanitizer.text(j['subject'], maxLength: 20),
        details: InputSanitizer.text(j['details'], maxLength: 1000),
        senderName: InputSanitizer.text(j['sender_name'], maxLength: 100),
        senderEmail: InputSanitizer.text(j['sender_email'], maxLength: 100),
        senderPhone: InputSanitizer.text(j['sender_phone'], maxLength: 30),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      );

  FeedbackEntry toEntity() => FeedbackEntry(
        id: id,
        subject: FeedbackSubject.values.firstWhere(
          (s) => s.name == subject,
          orElse: () => FeedbackSubject.inquiry,
        ),
        details: details,
        senderName: senderName,
        senderEmail: senderEmail,
        senderPhone: senderPhone,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'details': details,
        'sender_name': senderName,
        'sender_email': senderEmail,
        'sender_phone': senderPhone,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
