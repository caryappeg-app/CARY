// Domain: حالة استخدام — عرض كل آراء العملاء (للمالك والأدمن)
import '../entities/feedback_entry.dart';
import '../repositories/feedback_repository.dart';

class GetAllFeedback {
  final FeedbackRepository _repository;
  const GetAllFeedback(this._repository);

  Future<List<FeedbackEntry>> call() => _repository.getAll();
}
