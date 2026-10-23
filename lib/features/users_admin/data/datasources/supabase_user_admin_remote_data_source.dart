// Data: إدارة المستخدمين على Supabase.
// القراءة: جدول profiles (RLS: المالك/الأدمن بس يشوفوا الكل).
// التعديل وتغيير الصلاحية: RPC للمالك بس (السيرفر بيتحقق + بيمنع شيل آخر مالك).
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/user_profile.dart' show UserRole;
import '../../domain/entities/managed_user.dart';
import '../models/managed_user_model.dart';
import 'user_admin_remote_data_source.dart';

class SupabaseUserAdminRemoteDataSource implements UserAdminRemoteDataSource {
  final ApiClient _client;
  const SupabaseUserAdminRemoteDataSource(this._client);

  static ManagedUser _one(Object? json) {
    if (json is! Map) throw const ServerFailure();
    return ManagedUserModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<List<ManagedUser>> fetchAll() async {
    final json = await _client.get('/rest/v1/profiles', query: {
      'select': 'id,full_name,email,phone,role,created_at',
      'order': 'created_at.desc',
      'limit': 1000,
    });
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((m) => ManagedUserModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<ManagedUser> update({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) async =>
      _one(await _client.post('/rest/v1/rpc/admin_update_user', body: {
        'p_id': id,
        'p_full_name': fullName,
        'p_email': email,
        'p_phone': phone,
      }));

  @override
  Future<ManagedUser> setRole({
    required String id,
    required UserRole role,
  }) async =>
      _one(await _client.post('/rest/v1/rpc/admin_set_role', body: {
        'p_id': id,
        'p_role': role.name,
      }));

  /// بعد تسجيل الدخول: بروفايل المستخدم الحالي من السيرفر (الاسم + الصلاحية).
  /// الـ identifier مش بنستخدمه: السيرفر بيرجّع حساب صاحب الجلسة بس.
  @override
  Future<ManagedUser?> findByIdentifier(String identifier) async {
    final json = await _client.post('/rest/v1/rpc/my_profile', body: const {});
    return json is Map ? _one(json) : null;
  }

  /// البروفايل بيتعمل تلقائي في الداتابيز لما الحساب يتسجّل
  @override
  Future<void> add({
    required String fullName,
    required String email,
    required String phone,
  }) async {}
}
