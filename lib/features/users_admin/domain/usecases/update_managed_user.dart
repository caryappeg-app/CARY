// Domain: حالة استخدام — تعديل بيانات مستخدم (مع التحقق من المدخلات)
import '../../../../core/error/failure.dart';
import '../../../../core/validation/validators.dart';
import '../entities/managed_user.dart';
import '../repositories/user_admin_repository.dart';

class UpdateManagedUser {
  final UserAdminRepository _repository;
  const UpdateManagedUser(this._repository);

  Future<ManagedUser> call({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) {
    final error = Validators.requiredText(fullName, field: 'الاسم', max: 100) ??
        Validators.email(email) ??
        Validators.egyptianPhone(phone);
    if (error != null) throw ValidationFailure(error);
    return _repository.updateUser(
      id: id,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.replaceAll(RegExp(r'[\s\-]'), ''),
    );
  }
}
