// Domain: حالة استخدام — قراءة بيانات الحساب
import '../entities/user_profile.dart';
import '../repositories/account_repository.dart';

class GetUserProfile {
  final AccountRepository _repository;
  const GetUserProfile(this._repository);

  Future<UserProfile?> call() => _repository.getProfile();
}
