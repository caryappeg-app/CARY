// Data: مصادقة تجريبية (وضع الـ Mock) — بترجّع توكنز وهمية عشان الدخول التلقائي
// (Persistent Auth) يشتغل قبل ما الـ Backend يجهز. بتتبدّل بـ ApiAuthRemoteDataSource لوحدها.
import '../../../../core/security/token_store.dart';
import 'auth_remote_data_source.dart';

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  const MockAuthRemoteDataSource();

  static const _tokens = AuthTokens(
    accessToken: 'mock-access-token',
    refreshToken: 'mock-refresh-token',
  );

  @override
  Future<AuthTokens> signIn({
    required String identifier,
    required String password,
  }) async =>
      _tokens;

  @override
  Future<AuthTokens> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async =>
      _tokens;

  @override
  Future<AuthTokens?> refresh(String refreshToken) async => _tokens;

  @override
  Future<void> signOut(String accessToken) async {}
}
