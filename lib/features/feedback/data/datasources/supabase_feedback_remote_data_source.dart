// Data: الآراء على Supabase. الإرسال لأي مستخدم مسجّل، والعرض للمالك/الأدمن بس
// (RLS بيرجّع قايمة فاضية لو الطالب مش staff).
import '../../../../core/network/api_client.dart';
import '../models/feedback_model.dart';
import 'feedback_remote_data_source.dart';

class SupabaseFeedbackRemoteDataSource implements FeedbackRemoteDataSource {
  final ApiClient _client;
  const SupabaseFeedbackRemoteDataSource(this._client);

  @override
  Future<void> send(FeedbackModel model) async {
    await _client.post('/rest/v1/feedback', body: model.toJson());
  }

  @override
  Future<List<FeedbackModel>> fetchAll() async {
    final json = await _client.get('/rest/v1/feedback', query: {
      'select': 'id,subject,details,sender_name,sender_email,sender_phone,created_at',
      'order': 'created_at.desc',
      'limit': 500,
    });
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((m) => FeedbackModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// المالك فقط: الدالة على السيرفر بترفض أي حد غيره
  @override
  Future<void> delete(String id) async {
    await _client.post('/rest/v1/rpc/delete_feedback', body: {'p_id': id});
  }
}
