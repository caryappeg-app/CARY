// Presentation: شاشة "قريباً" / الحالة الفاضية لأي تاب
import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import 'app_top_bar.dart';

class SoonTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const SoonTab({
    required this.title,
    required this.icon,
    this.subtitle = 'قريباً',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: AppColors.icon),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
