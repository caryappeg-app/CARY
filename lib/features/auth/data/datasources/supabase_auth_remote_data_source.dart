// Data: المصادقة عبر Supabase Auth (GoTrue REST) فوق ApiClient.
// - الدخول بالإيميل أو الهاتف: الهاتف بيتحوّل لإيميل عن طريق RPC `email_for_identifier`.
// - التسجيل: بيبعت الاسم والهاتف في user_metadata، وtrigger في الداتابيز بيعمل البروفايل.
// مهم: لازم تقفل "Confirm email" من Supabase > Authentication > Providers > Email
// (التحقق من الإيميل بيتم عندك في شاشة التسجيل)، وإلا التسجيل مش هيرجّع جلسة.
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/token_store.dart';
import 'auth_remote_data_source.dart';

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final ApiClient _client; // لازم يكون DioApiClient.unauthenticated()
  const SupabaseAuthRemoteDataSource(this._client);

  static const _badLogin = UnauthorizedFailure('بيانات الدخول غير صحيحة');

  static AuthTokens _tokensFrom(Object? json) {
    if (json is! Map) throw const ServerFailure();
    final access = (json['access_token'] ?? '').toString();
    final refresh = (json['refresh_token'] ?? '').toString();
    if (access.isEmpty || refresh.isEmpty) throw const ServerFailure();
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  /// إيميل → زي ما هو. هاتف → الإيميل المسجّل بيه (أو null لو مش موجود)
  Future<String?> _emailFor(String identifier) async {
    final id = identifier.trim();
    if (id.contains('@')) return id.toLowerCase();
    final res = await _client.post(
      '/rest/v1/rpc/email_for_identifier',
      body: {'identifier': id},
    );
    final email = res is String ? res.trim() : '';
    return email.isEmpty ? null : email;
  }

  @override
  Future<AuthTokens> signIn({
    required String identifier,
    required String password,
  }) async {
    final email = await _emailFor(identifier);
    // نفس الرسالة لو الحساب مش موجود أو كلمة السر غلط (من غير كشف أيهما)
    if (email == null) throw _badLogin;
    try {
      final json = await _client.post(
        '/auth/v1/token?grant_type=password',
        body: {'email': email, 'password': password},
      );
      return _tokensFrom(json);
    } on ValidationFailure {
      throw _badLogin;
    } on UnauthorizedFailure {
      throw _badLogin;
    }
  }

  @override
  Future<AuthTokens> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final taken = await _client.post(
      '/rest/v1/rpc/identifier_taken',
      body: {'p_email': email, 'p_phone': phone},
    );
    if (taken == true) {
      throw const ValidationFailure('الإيميل أو رقم الهاتف مستخدم في حساب تاني');
    }
    try {
      final json = await _client.post('/auth/v1/signup', body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'data': {'full_name': fullName, 'phone': phone},
      });
      return _tokensFrom(json);
    } on ValidationFailure {
      throw const ValidationFailure(
          'تعذّر إنشاء الحساب، اتأكد من البيانات (كلمة السر 6 حروف على الأقل)');
    }
  }

  @override
  Future<AuthTokens?> refresh(String refreshToken) async {
    try {
      final json = await _client.post(
        '/auth/v1/token?grant_type=refresh_token',
        body: {'refresh_token': refreshToken},
      );
      return _tokensFrom(json);
    } on UnauthorizedFailure {
      return null; // الجلسة انتهت نهائيًا
    } on ValidationFailure {
      return null; // refresh token غير صالح / مستخدم قبل كده
    }
  }

  @override
  Future<void> signOut(String accessToken) async {
    try {
      await _client.post(
        '/auth/v1/logout',
        body: const {},
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } catch (_) {
      // مش حرج: التوكنز بتتمسح محليًا في كل الأحوال
    }
  }
}
