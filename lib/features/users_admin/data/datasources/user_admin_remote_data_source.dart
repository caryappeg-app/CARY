// Data: مصدر بيانات المستخدمين.
// Mock (الافتراضي): قايمة في الذاكرة بتبدأ بالحسابات الثابتة + أي حساب جديد يتسجّل.
// Api: بيشتغل لما USE_MOCK_DATA=false + API_BASE_URL. السيرفر لازم يتحقق إن الطالب "مالك"،
// وإن الصلاحيات (مالك/أدمن/مستخدم) بتتطبّق من جهته.
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/data/datasources/account_mock_data.dart';
import '../../../account/domain/entities/user_profile.dart'
    show UserProfile, UserRole;
import '../../domain/entities/managed_user.dart';
import '../models/managed_user_model.dart';

abstract class UserAdminRemoteDataSource {
  Future<List<ManagedUser>> fetchAll();
  Future<ManagedUser> update({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  });
  Future<ManagedUser> setRole({required String id, required UserRole role});
  Future<ManagedUser?> findByIdentifier(String identifier);
  Future<void> add({
    required String fullName,
    required String email,
    required String phone,
  });
}

class MockUserAdminRemoteDataSource implements UserAdminRemoteDataSource {
  final List<ManagedUser> _users = [
    for (final UserProfile p in kMockAccounts)
      ManagedUser(
        id: 'u_${p.phone}',
        fullName: p.fullName,
        email: p.email,
        phone: p.phone,
        role: p.role,
      ),
  ];

  static const _latency = Duration(milliseconds: 300);

  int _indexOf(String id) {
    final i = _users.indexWhere((u) => u.id == id);
    if (i < 0) throw const NotFoundFailure('المستخدم غير موجود');
    return i;
  }

  bool _sameIdentity(ManagedUser u, String email, String phone) =>
      (email.isNotEmpty && u.email.toLowerCase() == email.toLowerCase()) ||
      (phone.isNotEmpty && u.phone == phone);

  @override
  Future<List<ManagedUser>> fetchAll() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_users);
  }

  @override
  Future<ManagedUser> update({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await Future<void>.delayed(_latency);
    final i = _indexOf(id);
    final clash = _users.any((u) => u.id != id && _sameIdentity(u, email, phone));
    if (clash) {
      throw const ValidationFailure('الإيميل أو رقم الهاتف مستخدم في حساب تاني');
    }
    return _users[i] = _users[i].copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
    );
  }

  @override
  Future<ManagedUser> setRole({
    required String id,
    required UserRole role,
  }) async {
    await Future<void>.delayed(_latency);
    final i = _indexOf(id);
    final current = _users[i];
    // لازم يفضل مالك واحد على الأقل
    if (current.role == UserRole.owner &&
        role != UserRole.owner &&
        _users.where((u) => u.role == UserRole.owner).length <= 1) {
      throw const ValidationFailure('لازم يفضل مالك واحد على الأقل للتطبيق');
    }
    return _users[i] = current.copyWith(role: role);
  }

  @override
  Future<ManagedUser?> findByIdentifier(String identifier) async {
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty) return null;
    for (final u in _users) {
      if (u.email.toLowerCase() == id || u.phone == id) return u;
    }
    return null;
  }

  @override
  Future<void> add({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    if (_users.any((u) => _sameIdentity(u, email, phone))) return;
    _users.add(ManagedUser(
      id: 'u_${phone.isNotEmpty ? phone : email}',
      fullName: fullName,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    ));
  }
}

/// REST: GET /admin/users ، POST /admin/users/update ، POST /admin/users/role
class ApiUserAdminRemoteDataSource implements UserAdminRemoteDataSource {
  final ApiClient _client;
  const ApiUserAdminRemoteDataSource(this._client);

  static ManagedUser _one(Object? json) {
    if (json is! Map<String, dynamic>) throw const ServerFailure();
    return ManagedUserModel.fromJson(json);
  }

  @override
  Future<List<ManagedUser>> fetchAll() async {
    final json = await _client.get('/admin/users');
    final list = json is List
        ? json
        : (json is Map<String, dynamic> ? json['items'] : null);
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ManagedUserModel.fromJson)
        .toList();
  }

  @override
  Future<ManagedUser> update({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) async =>
      _one(await _client.post('/admin/users/update', body: {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
      }));

  @override
  Future<ManagedUser> setRole({
    required String id,
    required UserRole role,
  }) async =>
      _one(await _client.post('/admin/users/role', body: {
        'id': id,
        'role': role.name,
      }));

  /// الحساب والصلاحيات بتيجي من السيرفر وقت تسجيل الدخول
  @override
  Future<ManagedUser?> findByIdentifier(String identifier) async => null;

  /// الحساب بيتعمل في السيرفر وقت التسجيل (POST /auth/register)
  @override
  Future<void> add({
    required String fullName,
    required String email,
    required String phone,
  }) async {}
}
