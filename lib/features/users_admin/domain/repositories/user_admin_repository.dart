// Domain: عقد إدارة المستخدمين (للمالك)
import '../../../account/domain/entities/user_profile.dart' show UserRole;
import '../entities/managed_user.dart';

abstract class UserAdminRepository {
  Future<List<ManagedUser>> getUsers();

  Future<ManagedUser> updateUser({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  });

  /// تغيير حالة الحساب (مالك / أدمن / مستخدم)
  Future<ManagedUser> setRole({required String id, required UserRole role});

  /// بيانات الحساب المعدّلة من المالك (لو موجودة) — بتتطبق عند تسجيل الدخول
  Future<ManagedUser?> findByIdentifier(String identifier);

  /// بعد إنشاء حساب جديد: بيظهر في قايمة المستخدمين
  Future<void> trackRegistration({
    required String fullName,
    required String email,
    required String phone,
  });
}
