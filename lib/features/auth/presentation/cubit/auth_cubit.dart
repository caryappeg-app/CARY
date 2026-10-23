// Presentation: منطق المصادقة (Auto Login + Persistent Auth).
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckAuthStatusUseCase _checkAuthStatus;
  final LogoutUseCase _logout;
  late final StreamSubscription<void> _expiredSub;

  AuthCubit({
    required CheckAuthStatusUseCase checkAuthStatus,
    required LogoutUseCase logout,
    required Stream<void> sessionExpired,
  })  : _checkAuthStatus = checkAuthStatus,
        _logout = logout,
        super(const AuthInitial()) {
    _expiredSub = sessionExpired.listen((_) {
      if (!isClosed) emit(const AuthUnauthenticated(sessionExpired: true));
    });
  }

  /// بيتنادى من الـ Splash مرة واحدة عند فتح التطبيق.
  Future<void> checkAuthStatus() async {
    if (state is! AuthInitial) return;
    try {
      final ok = await _checkAuthStatus();
      if (isClosed) return;
      emit(ok ? const AuthAuthenticated() : const AuthUnauthenticated());
    } catch (_) {
      if (!isClosed) emit(const AuthUnauthenticated());
    }
  }

  /// بعد نجاح تسجيل الدخول (التوكنز اتحفظت في الـ Repository).
  void markAuthenticated() {
    if (!isClosed) emit(const AuthAuthenticated());
  }

  Future<void> signOut() async {
    try {
      await _logout();
    } catch (_) {
      // المسح المحلي بيحصل في كل الأحوال داخل الـ Repository
    }
    if (!isClosed) emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _expiredSub.cancel();
    return super.close();
  }
}
