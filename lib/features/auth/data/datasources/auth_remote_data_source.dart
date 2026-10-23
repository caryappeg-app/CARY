// Data: عقد مصدر المصادقة البعيد + تطبيق REST جاهز فوق ApiClient.
// عدّل أسماء الـ endpoints هنا بس لو الـ Backend مختلف — باقي التطبيق ميتغيرش.
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/token_store.dart';

abstract class AuthRemoteDataSource {
  /// بيرجّع التوكنز بعد نجاح تسجيل الدخول
  Future<AuthTokens> signIn({
    required String identifier,
    required String password,
  });

  Future<AuthTokens> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// بيرجّع null لو الـ refresh token انتهى أو اترفض
  Future<AuthTokens?> refresh(String refreshToken);

  Future<void> signOut(String accessToken);
}

/// تطبيق REST: مبيستلمش ولا بيرجّع أي بيانات حساسة في الـ logs،
/// وأي فشل بيترجم لـ Failure آمن من الـ ApiClient نفسه.
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  final ApiClient _client;
  const ApiAuthRemoteDataSource(this._client);

  static AuthTokens _tokensFrom(Object? json) {
    if (json is! Map<String, dynamic>) throw const ServerFailure();
    final access = (json['access_token'] ?? '').toString();
    final refresh = (json['refresh_token'] ?? '').toString();
    if (access.isEmpty || refresh.isEmpty) throw const ServerFailure();
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<AuthTokens> signIn({
    required String identifier,
    required String password,
  }) async {
    final json = await _client.post('/auth/login', body: {
      'identifier': identifier,
      'password': password,
    });
    return _tokensFrom(json);
  }

  @override
  Future<AuthTokens> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _client.post('/auth/register', body: {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return _tokensFrom(json);
  }

  @override
  Future<AuthTokens?> refresh(String refreshToken) async {
    try {
      final json = await _client.post('/auth/refresh', body: {
        'refresh_token': refreshToken,
      });
      return _tokensFrom(json);
    } on UnauthorizedFailure {
      return null; // الجلسة انتهت نهائيًا
    } on ValidationFailure {
      return null; // 400: refresh token غير صالح
    }
  }

  @override
  Future<void> signOut(String accessToken) async {
    try {
      await _client.post(
        '/auth/logout',
        body: const {},
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } catch (_) {
      // مش حرج: التوكنز بتتمسح محليًا في كل الأحوال
    }
  }
}
