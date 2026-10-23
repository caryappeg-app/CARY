// Data: التحقق من الإيميل بكود (OTP) أثناء التسجيل.
// Supabase: الكود بيتبعت من SMTP المربوط بالمشروع (Gmail مثلًا)، والسيرفر هو اللي بيتحقق منه.
// الترتيب: sendCode -> verifyCode -> completeSignUp (كلمة السر + الاسم + الهاتف).
import '../../../../core/config/app_config.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/token_store.dart';

abstract class EmailVerificationService {
  /// طول الكود اللي بيوصل للمستخدم
  int get codeLength;

  /// [resend] = true لإعادة الإرسال من نافذة الكود: بيبعت كود جديد من غير
  /// ما يفحص "الإيميل مسجّل" تاني (الفحص اتعمل قبل الإرسال الأول).
  Future<void> sendCode(String email, {bool resend = false});

  /// نسيت كلمة المرور: بيتأكد إن الحساب مسجّل بالفعل قبل ما يبعت الرمز.
  /// لو مش مسجّل بيرمي ValidationFailure برسالة "الحساب غير مسجّل... أنشئ حساب".
  Future<void> sendResetCode(String email, {bool resend = false});

  /// بعد verifyCode: بيحدد كلمة المرور الجديدة وبيقفل الجلسة المؤقتة
  Future<void> resetPassword({required String email, required String password});
  Future<void> verifyCode(String email, String code);

  /// بعد التحقق: بيحدد كلمة السر وبيكمّل الاسم والهاتف، وبعدين بيقفل الجلسة المؤقتة
  Future<void> completeSignUp({
    required String email,
    required String fullName,
    required String phone,
    required String password,
  });
}

/// وضع التجربة (من غير Backend): أي كود بطول 4 بيتقبل
class MockEmailVerification implements EmailVerificationService {
  const MockEmailVerification();
  @override
  int get codeLength => 4;
  @override
  Future<void> sendCode(String email, {bool resend = false}) =>
      Future<void>.delayed(const Duration(seconds: 1));
  @override
  Future<void> sendResetCode(String email, {bool resend = false}) =>
      Future<void>.delayed(const Duration(seconds: 1));
  @override
  Future<void> resetPassword(
          {required String email, required String password}) =>
      Future<void>.delayed(const Duration(seconds: 1));
  @override
  Future<void> verifyCode(String email, String code) =>
      Future<void>.delayed(const Duration(seconds: 1));
  @override
  Future<void> completeSignUp({
    required String email,
    required String fullName,
    required String phone,
    required String password,
  }) =>
      Future<void>.delayed(const Duration(seconds: 1));
}

class SupabaseEmailVerification implements EmailVerificationService {
  final ApiClient _client; // DioApiClient.unauthenticated()
  SupabaseEmailVerification(this._client);

  // جلسة مؤقتة في الذاكرة بس (بتتمسح بعد إكمال التسجيل)
  AuthTokens? _session;
  String? _verifiedEmail;

  /// لازم يطابق "Email OTP Length" في إعدادات Supabase (بيتظبط بـ OTP_LENGTH)
  @override
  int get codeLength => AppConfig.otpLength;

  static String _norm(String e) => e.trim().toLowerCase();

  @override
  Future<void> sendCode(String email, {bool resend = false}) async {
    if (!resend) {
      final taken = await _client.post('/rest/v1/rpc/identifier_taken',
          body: {'p_email': _norm(email), 'p_phone': ''});
      if (taken == true) {
        throw const ValidationFailure('الإيميل ده مسجّل قبل كده، سجّل الدخول');
      }
    }
    await _sendOtp(email, createUser: true);
  }

  Future<void> _sendOtp(String email, {required bool createUser}) async {
    try {
      await _client.post('/auth/v1/otp',
          body: {'email': _norm(email), 'create_user': createUser});
    } on ValidationFailure {
      // 429 (طلبات كتير) أو إعدادات الإيميل مش مظبوطة
      throw const ValidationFailure(
          'تعذّر إرسال الرمز، استنى دقيقة وجرّب تاني');
    }
  }

  @override
  Future<void> sendResetCode(String email, {bool resend = false}) async {
    if (!resend) {
      final exists = await _client.post('/rest/v1/rpc/identifier_taken',
          body: {'p_email': _norm(email), 'p_phone': ''});
      if (exists != true) {
        throw const ValidationFailure(
            'الحساب غير مسجّل من قبل، أنشئ حساب جديد');
      }
    }
    // create_user:false => عمره ما بيعمل حساب جديد من هنا
    await _sendOtp(email, createUser: false);
  }

  @override
  Future<void> resetPassword(
      {required String email, required String password}) async {
    final s = _session;
    if (s == null || _verifiedEmail != _norm(email)) {
      throw const ValidationFailure('لازم تتحقق من الإيميل الأول');
    }
    final auth = {'Authorization': 'Bearer ${s.accessToken}'};
    try {
      await _client.put('/auth/v1/user',
          body: {'password': password}, headers: auth);
    } on ValidationFailure {
      throw const ValidationFailure(
          'تعذّر حفظ كلمة المرور، اختار كلمة مختلفة عن القديمة (6 حروف على الأقل)');
    }
    try {
      await _client.post('/auth/v1/logout', body: const {}, headers: auth);
    } catch (_) {}
    _session = null;
    _verifiedEmail = null;
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    try {
      final json = await _client.post('/auth/v1/verify',
          body: {'type': 'email', 'email': _norm(email), 'token': code});
      final access = json is Map ? (json['access_token'] ?? '').toString() : '';
      final refresh =
          json is Map ? (json['refresh_token'] ?? '').toString() : '';
      if (access.isEmpty || refresh.isEmpty) throw const ServerFailure();
      _session = AuthTokens(accessToken: access, refreshToken: refresh);
      _verifiedEmail = _norm(email);
    } on ValidationFailure {
      throw const ValidationFailure('الرمز غير صحيح أو منتهي');
    } on UnauthorizedFailure {
      throw const ValidationFailure('الرمز غير صحيح أو منتهي');
    }
  }

  @override
  Future<void> completeSignUp({
    required String email,
    required String fullName,
    required String phone,
    required String password,
  }) async {
    final s = _session;
    if (s == null || _verifiedEmail != _norm(email)) {
      throw const ValidationFailure('لازم تتحقق من الإيميل الأول');
    }
    final auth = {'Authorization': 'Bearer ${s.accessToken}'};

    final phoneTaken = await _client.post('/rest/v1/rpc/identifier_taken',
        body: {'p_email': '', 'p_phone': phone});
    if (phoneTaken == true) {
      throw const ValidationFailure('رقم الهاتف مستخدم في حساب تاني');
    }

    try {
      await _client.put('/auth/v1/user', body: {'password': password}, headers: auth);
      await _client.post('/rest/v1/rpc/complete_signup',
          body: {'p_full_name': fullName, 'p_phone': phone}, headers: auth);
    } on ValidationFailure {
      throw const ValidationFailure(
          'تعذّر إنشاء الحساب، اتأكد من البيانات (كلمة السر 6 حروف على الأقل)');
    }

    // قفل الجلسة المؤقتة: المستخدم هيسجّل الدخول بنفسه بعد كده
    try {
      await _client.post('/auth/v1/logout', body: const {}, headers: auth);
    } catch (_) {}
    _session = null;
    _verifiedEmail = null;
  }
}
