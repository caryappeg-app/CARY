// Domain: التحقق من وجود جلسة/توكن صالح.
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repository;
  const CheckAuthStatusUseCase(this._repository);

  Future<bool> call() => _repository.hasActiveSession();
}
