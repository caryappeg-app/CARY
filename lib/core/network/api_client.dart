import '../security/token_store.dart';

// Core: عقد العميل الشبكي — الـ Data Sources بتتعامل معاه هو بس (مش مع Dio مباشرةً).
// بيرمي Failure آمن (من core/error/failure.dart) لما أي طلب يفشل.
abstract class ApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? query});
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers});
  Future<dynamic> put(String path,
      {Object? body, Map<String, String>? headers});
}

/// بيجدد التوكن لما ينتهي (بيتنفذ في الـ Data layer بتاع الـ Auth لاحقًا)
abstract class TokenRefresher {
  /// بيرجّع التوكنز الجديدة، أو null لو الـ refresh token نفسه انتهى
  Future<AuthTokens?> refresh(String refreshToken);
}
