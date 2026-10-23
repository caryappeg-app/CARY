// Presentation (مشترك): سطر تاريخ ووقت (أيقونة + عنوان + القيمة) بيتستخدم في كروت
// إدارة الإعلانات وإدارة الحجوزات.
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class DateInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const DateInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.subtitle;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: c),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.w800, color: c),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.title),
                ),
              ]),
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
