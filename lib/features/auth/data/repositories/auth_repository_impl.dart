// Data: تطبيق AuthRepository — بيخزّن التوكنز في التخزين الآمن (TokenStore)
// وبيطبّق TokenRefresher عشان DioApiClient يجدد الجلسة تلقائيًا عند 401.
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_events.dart';
import '../../../../core/security/token_store.dart';
import '../../../../core/utils/jwt_utils.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository, TokenRefresher {
  final AuthRemoteDataSource _remote;
  final TokenStore _tokens;
  final SessionEvents _events;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStore tokens,
    required SessionEvents events,
  })  : _remote = remote,
        _tokens = tokens,
        _events = events;

  @override
  Stream<void> get sessionExpired => _events.onExpired;

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final tokens = await _remote.signIn(
        identifier: identifier,
        password: password,
      );
      // rememberMe = false: بنحفظ العلامة، والـ Splash بيمسح الجلسة عند الفتح الجديد.
      await _tokens.save(tokens);
      await _tokens.setRememberMe(rememberMe);
    } catch (e) {
      throw mapToFailure(e); // رسالة آمنة بس للمستخدم
    }
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final tokens = await _remote.signUp(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      await _tokens.save(tokens);
    } catch (e) {
      throw mapToFailure(e);
    }
  }

  @override
  Future<AuthTokens?> refreshSession(String refreshToken) =>
      _remote.refresh(refreshToken);

  // TokenRefresher: بيتنادى من _AuthInterceptor جوه DioApiClient
  @override
  Future<AuthTokens?> refresh(String refreshToken) => refreshSession(refreshToken);

  @override
  Future<void> signOut() async {
    final access = await _tokens.accessToken;
    try {
      if (access != null && access.isNotEmpty) await _remote.signOut(access);
    } finally {
      await _tokens.clear(); // المسح المحلي بيحصل في كل الأحوال
    }
  }

  @override
  Future<bool> hasActiveSession() async {
    final access = await _tokens.accessToken;
    final refresh = await _tokens.refreshToken;
    final hasAccess = access != null && access.isNotEmpty;
    final hasRefresh = refresh != null && refresh.isNotEmpty;
    if (!hasAccess && !hasRefresh) return false;

    // "تذكرني" مش مفعّل: الجلسة كانت للتشغيل الماضي بس
    if (!await _tokens.rememberMe) {
      await _tokens.clear();
      return false;
    }

    // Access Token لسه صالح (فحص محلي من غير شبكة)
    if (hasAccess && !JwtUtils.isExpired(access)) return true;

    if (!hasRefresh) {
      await _tokens.clear();
      return false;
    }

    try {
      final fresh = await _remote.refresh(refresh);
      if (fresh == null) {
        await _tokens.clear(); // الـ refresh token اترفض
        return false;
      }
      await _tokens.save(fresh);
      return true;
    } on Failure catch (e) {
      // أوفلاين / سيرفر واقع: نسيب المستخدم داخل (الـ Interceptor هيجدد بعدين)
      return e is NetworkFailure || e is TimeoutFailure || e is ServerFailure;
    } catch (_) {
      return false;
    }
  }
}
