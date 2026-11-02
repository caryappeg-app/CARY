import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'constants/app_colors.dart';
import 'constants/theme_controller.dart';
import 'core/deeplink/deep_link_service.dart';
import 'core/di/injection.dart';
import 'core/push/notification_router.dart';
import 'core/widgets/desktop_responsive_wrapper.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'core/widgets/deferred_loader.dart';
import 'screens/login_screen.dart' deferred as login_screen;
import 'screens/splash_screen.dart';
import 'features/home/presentation/pages/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد مسار الضغط على الإشعارات قبل الإقلاع
  final notifier = Injector.instance.systemNotifier;
  notifier.onTap = (payload) => NotificationRouter.instance.open(payload);

  // إقلاع فوري للتطبيق دون حظر الإطار الأول (First Frame)
  runApp(const CaryApp());

  // تأجيل كافة العمليات والخدمات الثانوية لما بعد رسم أول إطار على الشاشة
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final futures = <Future<void>>[];

    // 1. تفعيل أعلى معدل تحديث للشاشة على أجهزة أندرويد فقط
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      futures.add(FlutterDisplayMode.setHighRefreshRate().catchError((_) {}));
    }

    // 2. تهيئة الإشعارات في الخلفية
    futures.add(notifier.init().catchError((_) {}));

    // 3. تهيئة روابط المشاركة (Deep Links) في الخلفية
    futures.add(DeepLinkService.instance.init().catchError((_) {}));

    await Future.wait(futures);
  });
}

class CaryApp extends StatelessWidget {
  const CaryApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ThemeData _theme(bool dark) {
    final base = dark ? ThemeData.dark() : ThemeData.light();
    final tajawalText = base.textTheme.apply(
      fontFamily: 'Tajawal',
      fontFamilyFallback: const ['Tajawal'],
    );
    final tajawalPrimary = base.primaryTextTheme.apply(
      fontFamily: 'Tajawal',
      fontFamilyFallback: const ['Tajawal'],
    );
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: 'Tajawal',
      fontFamilyFallback: const ['Tajawal'],
      scaffoldBackgroundColor: AppColors.surface,
      canvasColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.tone(0xFF0047CC),
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.blue,
        selectionHandleColor: AppColors.blue,
      ),
      textTheme: tajawalText,
      primaryTextTheme: tajawalPrimary,
      typography: Typography.material2021(
        platform: defaultTargetPlatform,
        black: tajawalText,
        white: tajawalText,
        englishLike: tajawalText,
        dense: tajawalText,
        tall: tajawalText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) {
            final cubit = Injector.instance.createAuthCubit();
            if (kIsWeb) cubit.checkAuthStatus();
            return cubit;
          },
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => Injector.instance.createNotificationsCubit(),
        ),
      ],
      child: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) => MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'CARY',
          // اللغة العربية + اتجاه من اليمين لليسار
          locale: const Locale('ar', 'EG'),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          builder: (context, child) => MultiBlocListener(
            listeners: [
              // انتهاء الجلسة أثناء الاستخدام (فشل Refresh) => رجوع لتسجيل الدخول
              BlocListener<AuthCubit, AuthState>(
                listenWhen: (_, curr) =>
                    curr is AuthUnauthenticated && curr.sessionExpired,
                listener: (_, __) =>
                    navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => DeferredWidget(
                      loadLibrary: login_screen.loadLibrary,
                      builder: () => login_screen.LoginScreen(),
                    ),
                  ),
                  (_) => false,
                ),
              ),
              // دخول / خروج / دخول تلقائي => الإشعارات تتفلتر حسب المستخدم الحالي
              BlocListener<AuthCubit, AuthState>(
                listenWhen: (_, curr) => curr is! AuthInitial,
                listener: (context, _) =>
                    context.read<NotificationsCubit>().syncViewer(),
              ),
            ],
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: DesktopResponsiveWrapper(
                child: ScaffoldMessenger(
                  child: child!,
                ),
              ),
            ),
          ),
          theme: _theme(ThemeController.instance.isDark),
          home: kIsWeb ? const HomeScreen() : const SplashScreen(),
        ),
      ),
    );
  }
}
