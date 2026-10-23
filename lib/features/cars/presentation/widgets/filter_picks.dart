// Presentation: خانات اختيار الفلاتر (الماركة / السنة / السعر)
import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../screens/car_brand.dart';
import '../../../../screens/field_tile.dart';

// =============================================================================
// خانات الفلتر (نفس شكل بيع سيارتك)
// =============================================================================

class BrandPick extends StatelessWidget {
  final CarBrand? brand;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const BrandPick({
    required this.brand,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final has = brand != null;
    return FieldTile(
      icon: Icons.directions_car_filled_outlined,
      label: 'الماركة',
      highlighted: has,
      onTap: onTap,
      trailing: has
          ? GestureDetector(
        onTap: onClear,
        child: Icon(Icons.close_rounded,
            color: AppColors.icon, size: 22),
      )
          : Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.icon, size: 26),
      child: Text(
        has ? brand!.nameAr : 'اختر الماركة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: has ? FontWeight.w700 : FontWeight.w500,
          color: has ? AppColors.title : AppColors.hint,
        ),
      ),
    );
  }
}

class FilterPick<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const FilterPick({
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null;
    return FieldTile(
      icon: icon,
      label: label,
      highlighted: has,
      onTap: () async {
        final r = await showPickerSheet<T>(
          context,
          title: label,
          items: items,
          labelOf: labelOf,
          selected: value,
          allLabel: 'الكل',
        );
        if (r != null) onChanged(r.value);
      },
      trailing: has
          ? GestureDetector(
        onTap: () => onChanged(null),
        child: Icon(Icons.close_rounded,
            color: AppColors.icon, size: 22),
      )
          : Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.icon, size: 26),
      child: Text(
        has ? labelOf(value as T) : hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: has ? FontWeight.w700 : FontWeight.w500,
          color: has ? AppColors.title : AppColors.hint,
        ),
      ),
    );
  }
}

// =============================================================================
// Radio Circle Custom Painter Widget
// =============================================================================

class RadioCircleIcon extends StatelessWidget {
  final bool isSelected;
  final Color color;
  final double size;

  const RadioCircleIcon({
    super.key,
    required this.isSelected,
    required this.color,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RadioPainter(isSelected: isSelected, color: color),
    );
  }
}

class _RadioPainter extends CustomPainter {
  final bool isSelected;
  final Color color;

  _RadioPainter({required this.isSelected, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusOuter = size.width / 2.0;

    final paintOuter = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radiusOuter * 0.85, paintOuter);

    if (isSelected) {
      final paintInner = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radiusOuter * 0.45, paintInner);
    }
  }

  @override
  bool shouldRepaint(_RadioPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected || oldDelegate.color != color;
}
