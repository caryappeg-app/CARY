// Domain: حالة استخدام — تغيير حالة حساب (مالك / أدمن / مستخدم)
import '../../../account/domain/entities/user_profile.dart' show UserRole;
import '../entities/managed_user.dart';
import '../repositories/user_admin_repository.dart';

class SetUserRole {
  final UserAdminRepository _repository;
  const SetUserRole(this._repository);

  Future<ManagedUser> call({required String id, required UserRole role}) =>
      _repository.setRole(id: id, role: role);
}
