import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';

/// خانة حقل بنفس شكل "بيع سيارتك": أيقونة زرقا + عنوان بالخط العريض،
/// وتحتهم القيمة أو النص الإرشادي.
class FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;
  final bool error;
  final bool highlighted;
  final VoidCallback? onTap;

  const FieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.error = false,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? AppColors.error
        : highlighted
            ? AppColors.blue
            : AppColors.fieldBorder;

    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: (error || highlighted) ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.blue, size: 24),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// نتيجة نافذة الاختيار: [value] بتبقى null لو المستخدم اختار "الكل".
/// ولو النافذة اتقفلت من غير اختيار بترجع null (مش PickResult).
class PickResult<T> {
  final T? value;
  const PickResult(this.value);
}

/// نافذة سفلية لاختيار عنصر من قايمة (نفس شكل بيع سيارتك).
Future<PickResult<T>?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  T? selected,
  String? allLabel,
}) {
  FocusScope.of(context).unfocus();
  final entries = <T?>[if (allLabel != null) null, ...items];

  return showModalBottomSheet<PickResult<T>>(
    context: context,
    barrierColor: ThemeController.barrierColor,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.tone(0xFFDDE3EC),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final v = entries[i];
                final sel = v == selected;
                return ListTile(
                  onTap: () => Navigator.of(ctx).pop(PickResult<T>(v)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  tileColor: sel ? AppColors.tileBg : null,
                  title: Text(
                    v == null ? allLabel! : labelOf(v as T),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? AppColors.blue : AppColors.title,
                    ),
                  ),
                  trailing: sel
                      ? Icon(Icons.check_circle, color: AppColors.blue)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
