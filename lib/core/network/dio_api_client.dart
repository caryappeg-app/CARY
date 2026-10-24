// Core: تطبيق ApiClient بـ Dio — HTTPS إجباري + Auth Interceptor + Refresh Token + Certificate Pinning.
// يحتاج الحزم: dio, crypto. الملف ده مش مستورد من أي مكان لحد ما تفعّله في core/di/injection.dart.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import '../security/token_store.dart';
import 'api_client.dart';

class DioApiClient implements ApiClient {
  final Dio _dio;
  DioApiClient._(this._dio);

  /// عميل بيضيف Bearer تلقائيًا ويجدد التوكن عند 401.
  /// [onSessionExpired] بيتنادى لما الـ refresh token نفسه يترفض (الجلسة خلصت).
  factory DioApiClient({
    required TokenStore tokens,
    required TokenRefresher refresher,
    void Function()? onSessionExpired,
  }) {
    final dio = _buildDio();
    // Dio منفصل (من غير interceptors) لإعادة الطلب بعد التجديد — بيمنع deadlock
    // في QueuedInterceptor لو الطلب المُعاد فشل برضه.
    final retryDio = _buildDio();
    dio.interceptors.add(
        _AuthInterceptor(retryDio, tokens, refresher, onSessionExpired));
    return DioApiClient._(dio);
  }

  /// عميل من غير Auth interceptor — لطلبات login / register / refresh.
  factory DioApiClient.unauthenticated() => DioApiClient._(_buildDio());

  static Dio _buildDio() {
    AppConfig.assertSecureConfig();
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        if (AppConfig.apiKey.isNotEmpty) 'apikey': AppConfig.apiKey,
      },
    ));
    _applyCertificatePinning(dio);
    return dio;
  }

  /// Certificate Pinning: بيقبل بس الشهادات اللي بصمتها في PINNED_CERT_SHA256
  static void _applyCertificatePinning(Dio dio) {
    final pins = AppConfig.pinnedCertSha256;
    if (pins.isEmpty) return;
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.validateCertificate = (X509Certificate? cert, String host, int port) {
        if (cert == null) return false;
        return pins.contains(sha256.convert(cert.der).toString());
      };
    }
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() => _dio.get<dynamic>(path, queryParameters: query));

  @override
  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers}) =>
      _guard(() => _dio.post<dynamic>(path,
          data: body, options: Options(headers: headers)));

  @override
  Future<dynamic> put(String path,
          {Object? body, Map<String, String>? headers}) =>
      _guard(() => _dio.put<dynamic>(path,
          data: body, options: Options(headers: headers)));

  @override
  Future<dynamic> delete(String path,
          {Object? body, Map<String, String>? headers}) =>
      _guard(() => _dio.delete<dynamic>(path,
          data: body, options: Options(headers: headers)));

  Future<dynamic> _guard(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw _toFailure(e); // رسالة آمنة بس — مفيش e.message ولا response.data
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  static Failure _toFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badCertificate:
        return const InsecureConnectionFailure();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) return const UnauthorizedFailure();
        if (code == 404) return const NotFoundFailure();
        if (code >= 400 && code < 500) return const ValidationFailure();
        if (code >= 500) return const ServerFailure();
        return const UnexpectedFailure();
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return e.error is SocketException
            ? const NetworkFailure()
            : const UnexpectedFailure();
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure();
    }
  }
}

/// بيضيف Bearer token لكل طلب، ولو رجع 401 بيجدد التوكن مرة واحدة ويعيد الطلب.
/// QueuedInterceptor => طلبات الـ 401 المتزامنة بتتعالج واحد ورا التاني، فمفيش
/// أكتر من refresh في نفس الوقت (مهم لو السيرفر بيلف الـ refresh token).
class _AuthInterceptor extends QueuedInterceptor {
  final Dio _retryDio;
  final TokenStore _tokens;
  final TokenRefresher _refresher;
  final void Function()? _onSessionExpired;
  _AuthInterceptor(
      this._retryDio, this._tokens, this._refresher, this._onSessionExpired);

  static const _retriedKey = 'auth_retried';
  static const _publicPaths = ['/auth/login', '/auth/register', '/auth/refresh'];

  bool _isPublic(RequestOptions o) => _publicPaths.any(o.path.endsWith);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublic(options) && options.headers['Authorization'] == null) {
      final token = await _tokens.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _isPublic(req) ||
        req.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    try {
      final current = await _tokens.accessToken;
      final sentWith = req.headers['Authorization'];

      String access;
      if (current != null &&
          current.isNotEmpty &&
          sentWith != null &&
          sentWith != 'Bearer $current') {
        // طلب سابق في الطابور جدّد التوكن بالفعل => نستخدمه من غير refresh جديد
        access = current;
      } else {
        final refresh = await _tokens.refreshToken;
        if (refresh == null || refresh.isEmpty) {
          await _expire();
          return handler.next(err);
        }
        final fresh = await _refresher.refresh(refresh);
        if (fresh == null) {
          await _expire(); // الـ refresh token اترفض => لازم تسجيل دخول جديد
          return handler.next(err);
        }
        await _tokens.save(fresh);
        access = fresh.accessToken;
      }

      req
        ..headers['Authorization'] = 'Bearer $access'
        ..extra[_retriedKey] = true;
      handler.resolve(await _retryDio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      // فشل شبكة/سيرفر أثناء التجديد: الجلسة بتفضل زي ما هي
      handler.next(err);
    }
  }

  Future<void> _expire() async {
    await _tokens.clear();
    _onSessionExpired?.call();
  }
}
