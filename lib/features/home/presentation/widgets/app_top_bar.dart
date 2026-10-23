// Presentation: الهيدر العلوي المشترك (لوجو + إشعارات + الوضع الداكن)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/theme_controller.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

// =============================================================================
// Top bar
// =============================================================================

class AppTopBar extends StatelessWidget {
  const AppTopBar();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(16, 10 + topInset, 16, 10),
      child: Row(
        children: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final unread = state.unread;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _CircleButton(
                    icon: unread > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    tooltip: 'الإشعارات',
                    onTap: () => NotificationsPage.open(context),
                  ),
                  if (unread > 0)
                    PositionedDirectional(
                      top: -2,
                      end: -2,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                ThemeController.logoAsset,
                height: 52,
                errorBuilder: (_, __, ___) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_filled_outlined,
                        color: AppColors.navy, size: 28),
                    Text(
                      'CARY',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: ThemeController.instance,
            builder: (context, _) {
              final dark = ThemeController.instance.isDark;
              return _CircleButton(
                icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                tooltip: dark ? 'الوضع الفاتح' : 'الوضع الداكن',
                onTap: ThemeController.instance.toggle,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(side: BorderSide(color: AppColors.fieldBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: AppColors.title, size: 26),
          ),
        ),
      ),
    );
  }
}
