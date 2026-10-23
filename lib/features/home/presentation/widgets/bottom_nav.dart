// Presentation: شريط التنقل السفلي
import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';

// =============================================================================
// Bottom navigation
// =============================================================================

class _NavData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavData(this.label, this.icon, this.activeIcon);
}

class AppBottomNav extends StatelessWidget {
  final int current;
  final int favCount;
  final int adsCount;
  final int bookingsCount;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    required this.current,
    required this.favCount,
    required this.adsCount,
    required this.bookingsCount,
    required this.onTap,
  });

  static const _items = [
    _NavData('الرئيسية', Icons.home_outlined, Icons.home_rounded),
    _NavData('إعلاناتي', Icons.directions_car_outlined,
        Icons.directions_car_filled),
    _NavData('بيع سيارتك', Icons.add_circle_outline, Icons.add_circle),
    _NavData('المفضلات', Icons.favorite_border, Icons.favorite),
    _NavData('حجوزاتي', Icons.calendar_month_outlined, Icons.calendar_month),
    _NavData('حسابي', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.tone(0xFFE5E9F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    selected: i == current,
                    badge: i == 3
                        ? favCount
                        : i == 1
                        ? adsCount
                        : i == 4
                        ? bookingsCount
                        : 0,
                    badgeColor: i == 1
                        ? AppColors.tone(0xFF16A34A)
                        : i == 4
                        ? AppColors.blue
                        : AppColors.badge,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool selected;
  final int badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.subtitle;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // ✅ الأيقونة صغيرة (24) وتكبر بفرق واضح (30) لما تتختار
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  selected ? data.activeIcon : data.icon,
                  key: ValueKey<bool>(selected),
                  color: color,
                  size: selected ? 30 : 24,
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: -7,
                  right: -9,
                  child: Container(
                    // ✅ دايرة ثابتة والرقم في منتصفها بالظبط
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Text(
                      '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}