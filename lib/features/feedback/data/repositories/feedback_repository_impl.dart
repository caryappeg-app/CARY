// Data: تطبيق FeedbackRepository
import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/feedback_entry.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_data_source.dart';
import '../models/feedback_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource _remote;
  const FeedbackRepositoryImpl(this._remote);

  @override
  Future<void> submit(FeedbackEntry entry) async {
    try {
      await _remote.send(FeedbackModel.fromEntity(entry));
    } catch (e) {
      throw mapToFailure(e); // رسالة آمنة بس للمستخدم
    }
  }

  @override
  Future<List<FeedbackEntry>> getAll() async {
    try {
      final models = await _remote.fetchAll();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw mapToFailure(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _remote.delete(id);
    } catch (e) {
      throw mapToFailure(e);
    }
  }
}
