// Data: موديل المستخدم — JSON <-> Entity (مع تنظيف النصوص القادمة من السيرفر)
import '../../../../core/validation/input_sanitizer.dart';
import '../../../account/domain/entities/user_profile.dart' show UserRoleX;
import '../../domain/entities/managed_user.dart';

class ManagedUserModel {
  static ManagedUser fromJson(Map<String, dynamic> j) => ManagedUser(
        id: InputSanitizer.text(j['id'], maxLength: 80),
        fullName: InputSanitizer.text(j['full_name'], maxLength: 100),
        email: InputSanitizer.text(j['email'], maxLength: 100),
        phone: InputSanitizer.text(j['phone'], maxLength: 30),
        role: UserRoleX.fromKey(j['role']?.toString()),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      );
}
