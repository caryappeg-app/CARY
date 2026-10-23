// Domain: مستخدم في شاشة "إدارة المستخدمين" (للمالك فقط)
import '../../../account/domain/entities/user_profile.dart' show UserRole;

class ManagedUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  /// حالة الحساب: مالك / أدمن / مستخدم
  final UserRole role;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.role = UserRole.user,
    this.createdAt,
  });

  ManagedUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
  }) =>
      ManagedUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}
