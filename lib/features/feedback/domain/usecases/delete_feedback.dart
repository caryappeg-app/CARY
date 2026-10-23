// Domain: حالة استخدام — حذف رأي عميل (للمالك فقط)
import '../repositories/feedback_repository.dart';

class DeleteFeedback {
  final FeedbackRepository _repository;
  const DeleteFeedback(this._repository);

  Future<void> call(String id) => _repository.delete(id);
}
