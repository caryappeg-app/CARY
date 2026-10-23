// Domain: حالة استخدام — تسجيل الخروج (مسح بيانات الجلسة)
import '../repositories/account_repository.dart';

class SignOut {
  final AccountRepository _repository;
  const SignOut(this._repository);

  Future<void> call() => _repository.signOut();
}
