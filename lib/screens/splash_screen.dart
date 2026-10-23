import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/home/presentation/pages/home_screen.dart';
import 'login_screen.dart';

/// شاشة البداية: لوجو CARY هو العربية نفسها — بيدخل من اليمين للشمال على الطريق
/// (خطوط سرعة + خطوط طريق بتجري) وبيفرمل في النص ويعمل "pop" صغير،
/// وبعدها الشعار يظهر. بتدعم الوضع الفاتح والداكن.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  // اللوجو (العربية) يدخل ويفرمل (أول 62% من الوقت)
  late final Animation<double> _drive = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.62, curve: Curves.easeOutCubic),
  );
  // "pop" صغير لما اللوجو يوقف
  late final Animation<double> _settle = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.60, 0.78, curve: Curves.linear),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.70, 0.92, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _c,
    curve: const Interval(0.70, 0.94, curve: Curves.easeOutCubic),
  ));
  late final Animation<double> _footerFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.10, 0.40, curve: Curves.easeOut),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.05, 1.0, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    // التحقق من الجلسة بيشتغل بالتوازي مع أنيميشن السبلاش
    context.read<AuthCubit>().checkAuthStatus();
    _c.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _goNext();
    });
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    // لو التحقق لسه شغال نستناه (Auto Login): مسجّل => الرئيسية، وإلا => تسجيل الدخول
    final cubit = context.read<AuthCubit>();
    final state = cubit.state is AuthInitial
        ? await cubit.stream.firstWhere((s) => s is! AuthInitial)
        : cubit.state;
    if (!mounted) return;
    final Widget target =
        state is AuthAuthenticated ? const HomeScreen() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _logoFallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_car_filled_outlined,
            color: AppColors.navy, size: 56),
        const SizedBox(height: 4),
        Text(
          'CARY',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
            fontSize: 30,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeController.instance.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SizedBox.expand(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------- مشهد الطريق: اللوجو هو العربية
                    SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          const logoW = 200.0, logoH = 96.0;
                          // true = اقلب اللوجو أفقيًا عشان يبص ناحية الحركة (شمال)
                          // (حطه true بس لو اللوجو مفيهوش كتابة، وإلا الكتابة هتتعكس)
                          const mirrorLogo = false;
                          final roadY = box.maxHeight * 0.86;
                          // بيبدأ برا الشاشة من اليمين ويتحرك للنص
                          final startOffset = box.maxWidth + 40;
                          final endX = (box.maxWidth - logoW) / 2;
                          final travel = endX - startOffset;

                          return AnimatedBuilder(
                            animation: _c,
                            builder: (context, _) {
                              final t = _drive.value;
                              final speed =
                              (3 * (1 - t) * (1 - t)).clamp(0.0, 1.0);
                              final x = startOffset + travel * t;
                              final bob =
                                  math.sin(_c.value * 160) * (0.4 + 1.6 * speed);
                              final pop =
                                  1 + 0.06 * math.sin(math.pi * _settle.value);
                              final top = roadY - logoH + bob - 2;

                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _RoadPainter(
                                        distance: travel * t,
                                        speed: speed,
                                        roadY: roadY,
                                        logoLeft: x,
                                        logoTop: top,
                                        logoW: logoW,
                                        logoH: logoH,
                                        road: AppColors.fieldBorder,
                                        lane: AppColors.hint,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: x,
                                    top: top,
                                    width: logoW,
                                    height: logoH,
                                    child: Transform.rotate(
                                      // مقدمة اللوجو (الشمال) ترتفع شوية وهو بيجري
                                      angle: 0.035 * speed,
                                      alignment: Alignment.bottomCenter,
                                      child: Transform.scale(
                                        scale: pop,
                                        alignment: Alignment.bottomCenter,
                                        child: Transform.flip(
                                          flipX: mirrorLogo,
                                          child: Image.asset(
                                            ThemeController.logoAsset,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                _logoFallback(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ---------- الشعار
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              'اشتري وبيع سيارتك بثقة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.title,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'فحص معتمد  •  أسعار واضحة  •  حجز سهل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- شريط التحميل تحت
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 56,
                child: FadeTransition(
                  opacity: _footerFade,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 150,
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              minHeight: 4,
                              backgroundColor: AppColors.fieldBorder,
                              valueColor:
                              AlwaysStoppedAnimation(AppColors.blue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.hint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بيرسم الطريق: خط الأسفلت + خطوط متقطعة بتجري عكس الاتجاه + ضل اللوجو
/// + خطوط سرعة ورا اللوجو من ناحية اليمين (بتختفي مع الفرملة).
class _RoadPainter extends CustomPainter {
  final double distance; // المسافة اللي اللوجو مشاها (بتحرّك خطوط الطريق)
  final double speed; // 0..1
  final double roadY;
  final double logoLeft;
  final double logoTop;
  final double logoW;
  final double logoH;
  final Color road;
  final Color lane;

  _RoadPainter({
    required this.distance,
    required this.speed,
    required this.roadY,
    required this.logoLeft,
    required this.logoTop,
    required this.logoW,
    required this.logoH,
    required this.road,
    required this.lane,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ---- الطريق
    canvas.drawLine(
      Offset(0, roadY),
      Offset(size.width, roadY),
      Paint()
        ..color = road
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ---- خطوط الطريق المتقطعة (بتجري لليمين عكس اتجاه اللوجو)
    const dash = 26.0, gap = 24.0, period = dash + gap;
    final offset = (-distance) % period;
    final lanePaint = Paint()
      ..color = lane
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (double dx = offset - period; dx < size.width + period; dx += period) {
      canvas.drawLine(
          Offset(dx, roadY + 16), Offset(dx + dash, roadY + 16), lanePaint);
    }

    // ---- ضل اللوجو
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(logoLeft + logoW / 2, roadY + 3),
        width: logoW * 0.8,
        height: 9,
      ),
      Paint()..color = Colors.black.withOpacity(0.16),
    );

    // ---- خطوط السرعة ورا اللوجو
    if (speed > 0.05) {
      for (var i = 0; i < 3; i++) {
        final y = logoTop + logoH * (0.35 + 0.2 * i);
        final begin = logoLeft + logoW - 6 + i * 8; // ورا اللوجو (ناحية اليمين)
        final len = (70 - i * 14) * speed;
        canvas.drawLine(
          Offset(begin, y),
          Offset(begin + len, y),
          Paint()
            ..color = lane.withOpacity(0.55 * speed)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}