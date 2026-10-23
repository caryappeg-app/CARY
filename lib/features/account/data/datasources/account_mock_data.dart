// Data: بيانات الحسابات الثابتة (لحد ما الـ API يتربط).
// بتتحفظ كبروفايل للمستخدم بعد تسجيل الدخول وبتظهر في حسابي > معلومات الحساب.
import '../../domain/entities/user_profile.dart';

/// الحساب الرئيسي — مالك التطبيق
const kMockUserProfile = UserProfile(
  fullName: 'محمد فتحي عبداللطيف',
  email: 'mohammed58r884@gmail.com',
  phone: '01201082852',
  role: UserRole.owner,
);

/// حساب أدمن
const kMockAdminProfile = UserProfile(
  fullName: 'عز الدين عبدالحميد عرفان',
  email: 'ezzelden@gmail.com',
  phone: '01000721118',
  role: UserRole.admin,
);

/// حساب مستخدم عادي
const kMockRegularUserProfile = UserProfile(
  fullName: 'عمر فتحي عبداللطيف',
  email: 'omar@gmail.com',
  phone: '01221683600',
  role: UserRole.user,
);

/// كل الحسابات الثابتة اللي ليها بيانات وحالات جاهزة
const kMockAccounts = [
  kMockUserProfile,
  kMockAdminProfile,
  kMockRegularUserProfile,
];