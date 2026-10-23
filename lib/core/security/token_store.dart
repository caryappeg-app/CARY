// Core: حفظ توكنز الدخول (Access / Refresh) في التخزين الآمن بس.
import 'secure_storage.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  const AuthTokens({required this.accessToken, required this.refreshToken});
}

class TokenStore {
  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';
  static const _kRemember = 'auth.remember_me';

  final SecureStorage _storage;
  const TokenStore(this._storage);

  Future<String?> get accessToken => _storage.read(_kAccess);
  Future<String?> get refreshToken => _storage.read(_kRefresh);

  /// "تذكرني": لو false الجلسة بتنتهي مع قفل التطبيق (بيتفحص في الـ Splash).
  Future<bool> get rememberMe async =>
      (await _storage.read(_kRemember)) != '0';

  Future<void> setRememberMe(bool value) =>
      _storage.write(_kRemember, value ? '1' : '0');

  Future<void> save(AuthTokens t) async {
    await _storage.write(_kAccess, t.accessToken);
    await _storage.write(_kRefresh, t.refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(_kAccess);
    await _storage.delete(_kRefresh);
    await _storage.delete(_kRemember);
  }
}
