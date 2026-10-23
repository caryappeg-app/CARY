// Domain: حالة استخدام — تسجيل الدخول بكلمة السر (مع التحقق من المدخلات)
import '../../../../core/error/failure.dart';
import '../../../../core/validation/validators.dart';
import '../repositories/auth_repository.dart';

class SignInWithPassword {
  final AuthRepository _repository;
  const SignInWithPassword(this._repository);

  Future<void> call({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) {
    final id = identifier.trim();
    final isEmail = id.contains('@');
    final idError = isEmail ? Validators.email(id) : Validators.egyptianPhone(id);
    if (idError != null) throw ValidationFailure(idError);
    final passError = Validators.password(password);
    if (passError != null) throw ValidationFailure(passError);
    return _repository.signIn(
      identifier: id,
      password: password,
      rememberMe: rememberMe,
    );
  }
}
