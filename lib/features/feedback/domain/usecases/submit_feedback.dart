// Domain: حالة استخدام — إرسال رأي (مع التحقق من القواعد)
import '../../../../core/error/failure.dart';
import '../entities/feedback_entry.dart';
import '../entities/feedback_rules.dart';
import '../repositories/feedback_repository.dart';

class SubmitFeedback {
  final FeedbackRepository _repository;
  const SubmitFeedback(this._repository);

  Future<void> call(FeedbackEntry entry) {
    final error = FeedbackRules.validate(
      subject: entry.subject,
      details: entry.details,
    );
    if (error != null) throw ValidationFailure(error);
    return _repository.submit(entry);
  }
}
