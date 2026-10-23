// Core: بيحوّل أي استثناء خام (Socket / Timeout / Format ...) لـ Failure آمن.
// الاستثناء الأصلي ما بيوصلش للـ UI أبدًا.
import 'dart:async';
import 'dart:io';

import 'failure.dart';

Failure mapToFailure(Object error) {
  assert(() {
    // ignore: avoid_print
    print('[debug-only] ${error.runtimeType}'); // نوع الخطأ بس، في وضع التطوير فقط
    return true;
  }());

  if (error is Failure) return error;
  if (error is SocketException) return const NetworkFailure();
  if (error is HandshakeException || error is TlsException) {
    return const InsecureConnectionFailure();
  }
  if (error is TimeoutException) return const TimeoutFailure();
  if (error is FormatException) return const ServerFailure();
  return const UnexpectedFailure();
}
