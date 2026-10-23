// Presentation: حالات المصادقة.
sealed class AuthState {
  const AuthState();
}

/// لسه بنتحقق من الجلسة (السبلاش).
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthUnauthenticated extends AuthState {
  /// true لما الجلسة خلصت أثناء الاستخدام (فشل تجديد التوكن)، مش خروج يدوي.
  final bool sessionExpired;
  const AuthUnauthenticated({this.sessionExpired = false});
}
