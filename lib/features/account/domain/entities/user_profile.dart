// Domain: بيانات حساب المستخدم المسجّل دخوله

/// حالة الحساب — بنستخدمها بعدين في الصلاحيات (مالك / أدمن / مستخدم)
enum UserRole { owner, admin, user }

extension UserRoleX on UserRole {
  /// الاسم اللي بيظهر في الواجهة جنب "حسابي"
  String get label => switch (this) {
    UserRole.owner => 'مالك',
    UserRole.admin => 'أدمن',
    UserRole.user => 'مستخدم',
  };

  /// اسم ثابت بنخزّنه في التخزين المحلي ونرجّعه منه
  String get key => name;

  static UserRole fromKey(String? key) => switch (key) {
    'owner' => UserRole.owner,
    'admin' => UserRole.admin,
    _ => UserRole.user,
  };
}

class UserProfile {
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;

  const UserProfile({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.role = UserRole.user,
  });
}