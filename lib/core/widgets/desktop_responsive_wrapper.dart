import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/theme_controller.dart';

/// ويدجت لضبط أبعاد ومظهر التطبيق عند فتحه على أجهزة الكمبيوتر (Desktop / Web)
/// - عند فتح التطبيق على شاشات عريضة (أكبر من 520px)، يتم عرض التطبيق في إطار موبايل
///   أنيق في منتصف الشاشة مع خلفية وظلال عصرية لمنع التمدد المشوّه.
/// - على شاشات الموبايل (أقل من 520px)، يعمل التطبيق بكامل العرض الافتراضي.
class DesktopResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const DesktopResponsiveWrapper({super.key, required this.child});

  /// العرض الأقصى لإطار الموبايل على شاشات الكمبيوتر
  static const double maxMobileWidth = 430.0;
  static const double desktopBreakpoint = 450.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > desktopBreakpoint) {
          final isDark = ThemeController.instance.isDark;
          final backdropBg =
              isDark ? const Color(0xFF080D18) : const Color(0xFFE8EEF5);
          final borderColor = AppColors.border.withValues(alpha: 0.5);

          return ColoredBox(
            color: backdropBg,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: maxMobileWidth),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(maxMobileWidth, constraints.maxHeight),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        }

        // على الهواتف والشاشات الصغيرة
        return child;
      },
    );
  }
}
