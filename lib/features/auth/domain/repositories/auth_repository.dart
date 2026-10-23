// Domain: عقد المصادقة (JWT / Firebase Auth / Supabase Auth).
// الـ UI والـ Cubits بيتعاملوا مع العقد ده بس — تغيير مزوّد المصادقة
// بيتعمل في الـ Data layer من غير ما أي شاشة تتغير.
import '../../../../core/security/token_store.dart';

abstract class AuthRepository {
  /// تسجيل الدخول بالهاتف أو الإيميل + كلمة السر.
  /// بيرمي [UnauthorizedFailure] لو البيانات غلط، و[ValidationFailure] لو ناقصة.
  Future<void> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  });

  /// إنشاء حساب جديد (بعد التحقق من الإيميل/الهاتف).
  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// تجديد الجلسة بالـ refresh token (بيستخدمه DioApiClient تلقائيًا).
  /// بيرجّع null لو الـ refresh token انتهى => المستخدم لازم يسجّل من جديد.
  Future<AuthTokens?> refreshSession(String refreshToken);

  /// تسجيل الخروج: بيمسح التوكنز من التخزين الآمن وبيبلغ السيرفر (لو متاح).
  Future<void> signOut();

  /// هل فيه جلسة صالحة؟ (بيتستخدم في الـ Splash عشان نتخطى شاشة الدخول).
  /// بيفحص صلاحية الـ Access Token محليًا، ولو خلص بيجدده بالـ Refresh Token.
  Future<bool> hasActiveSession();

  /// بيطلع حدث لما الجلسة تنتهي أثناء الاستخدام (الـ refresh token اترفض).
  Stream<void> get sessionExpired;
}
