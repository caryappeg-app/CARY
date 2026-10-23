// Domain: عقد الحساب
import '../entities/user_profile.dart';

abstract class AccountRepository {
  /// بيانات الحساب الحالي، أو null لو مفيش مستخدم مسجّل دخوله
  Future<UserProfile?> getProfile();

  /// بعد إنشاء حساب جديد: بنحفظ البيانات عشان تظهر لما يسجّل دخول
  Future<void> saveRegistration(UserProfile profile);

  /// بعد نجاح تسجيل الدخول بالهاتف أو الإيميل.
  /// TODO: لما الـ API يتربط، استبدلها بحفظ البروفايل اللي راجع من السيرفر.
  Future<void> signIn(String identifier);

  /// بيحفظ بيانات الحساب الحالي كما هي (مثلًا بعد تعديل المالك لها من إدارة المستخدمين)
  Future<void> applyProfile(UserProfile profile);

  Future<void> signOut();
}
