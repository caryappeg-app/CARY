// Data: مصدر إرسال وعرض الآراء.
// Mock (الافتراضي) بيحتفظ بالرسائل في الذاكرة طول ما التطبيق شغّال،
// و ApiFeedbackRemoteDataSource بيشتغل لما USE_MOCK_DATA=false + API_BASE_URL.
import '../../../../core/network/api_client.dart';
import '../models/feedback_model.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> send(FeedbackModel model);

  /// كل الآراء، الأحدث أولًا
  Future<List<FeedbackModel>> fetchAll();

  /// حذف رأي (للمالك فقط — السيرفر هو اللي بيتحقق)
  Future<void> delete(String id);
}

/// نسخة تجريبية: بتحاكي تأخير الشبكة وبتحتفظ بالرسائل في الذاكرة
class MockFeedbackRemoteDataSource implements FeedbackRemoteDataSource {
  final Duration latency;
  final List<Map<String, dynamic>> sent = [];

  MockFeedbackRemoteDataSource({
    this.latency = const Duration(milliseconds: 700),
  });

  @override
  Future<void> send(FeedbackModel model) async {
    await Future<void>.delayed(latency);
    sent.add({
      ...model.toJson(),
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<FeedbackModel>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return sent.reversed.map(FeedbackModel.fromJson).toList();
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sent.removeWhere((m) => m['id'] == id);
  }
}

/// REST: POST /feedback (إرسال) و GET /feedback (للمالك/الأدمن — السيرفر هو اللي بيتحقق من الصلاحية).
class ApiFeedbackRemoteDataSource implements FeedbackRemoteDataSource {
  final ApiClient _client;
  const ApiFeedbackRemoteDataSource(this._client);

  @override
  Future<void> send(FeedbackModel model) async {
    await _client.post('/feedback', body: model.toJson());
  }

  @override
  Future<List<FeedbackModel>> fetchAll() async {
    final json = await _client.get('/feedback');
    final list = json is List
        ? json
        : (json is Map<String, dynamic> ? json['items'] : null);
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(FeedbackModel.fromJson)
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    await _client.post('/feedback/delete', body: {'id': id});
  }
}
