// Domain: حالة استخدام — قايمة كل المستخدمين
import '../entities/managed_user.dart';
import '../repositories/user_admin_repository.dart';

class GetManagedUsers {
  final UserAdminRepository _repository;
  const GetManagedUsers(this._repository);

  Future<List<ManagedUser>> call() => _repository.getUsers();
}
