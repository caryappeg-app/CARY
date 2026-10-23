import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'constants/theme_controller.dart';
import 'core/deeplink/deep_link_service.dart';
import 'core/di/injection.dart';
import 'core/push/notification_router.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // أعلى معدّل تحديث للشاشة يدعمه الجهاز (90/120Hz) بدل 60Hz الافتراضي على أندرويد
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }
  // إشعارات التليفون: الضغط على الإشعار بيفتح الشاشة المناسبة حسب نوعه
  final notifier = Injector.instance.systemNotifier;
  notifier.onTap = (payload) => NotificationRouter.instance.open(payload);
  await notifier.init();
  await DeepLinkService.instance.init(); // روابط مشاركة السيارات
  runApp(const CaryApp());
}

class CaryApp extends StatelessWidget {
  const CaryApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ThemeData _theme(bool dark) {
    final base = dark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
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
      textTheme: GoogleFonts.tajawalTextTheme(base.textTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => Injector.instance.createAuthCubit(),
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
          builder: (context, child) => MultiBlocListener(
            listeners: [
              // انتهاء الجلسة أثناء الاستخدام (فشل Refresh) => رجوع لتسجيل الدخول
              BlocListener<AuthCubit, AuthState>(
                listenWhen: (_, curr) =>
                    curr is AuthUnauthenticated && curr.sessionExpired,
                listener: (_, __) =>
                    navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
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
                textDirection: TextDirection.rtl, child: child!),
          ),
          theme: _theme(ThemeController.instance.isDark),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
