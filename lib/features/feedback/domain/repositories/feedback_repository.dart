// Domain: عقد الآراء (الشكاوى / الاقتراحات / الاستفسارات / التقييمات)
import '../entities/feedback_entry.dart';

abstract class FeedbackRepository {
  Future<void> submit(FeedbackEntry entry);

  /// كل الآراء المرسلة، الأحدث أولًا (للمالك والأدمن)
  Future<List<FeedbackEntry>> getAll();

  /// حذف رأي (المالك فقط)
  Future<void> delete(String id);
}
