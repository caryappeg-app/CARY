// Data: تطبيق UserAdminRepository
import '../../../../core/error/error_mapper.dart';
import '../../../account/domain/entities/user_profile.dart' show UserRole;
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/user_admin_repository.dart';
import '../datasources/user_admin_remote_data_source.dart';

class UserAdminRepositoryImpl implements UserAdminRepository {
  final UserAdminRemoteDataSource _remote;
  const UserAdminRepositoryImpl(this._remote);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw mapToFailure(e); // رسالة آمنة بس للمستخدم
    }
  }

  @override
  Future<List<ManagedUser>> getUsers() => _guard(_remote.fetchAll);

  @override
  Future<ManagedUser> updateUser({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) =>
      _guard(() => _remote.update(
          id: id, fullName: fullName, email: email, phone: phone));

  @override
  Future<ManagedUser> setRole({required String id, required UserRole role}) =>
      _guard(() => _remote.setRole(id: id, role: role));

  @override
  Future<ManagedUser?> findByIdentifier(String identifier) async {
    try {
      return await _remote.findByIdentifier(identifier);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> trackRegistration({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    try {
      await _remote.add(fullName: fullName, email: email, phone: phone);
    } catch (_) {}
  }
}
