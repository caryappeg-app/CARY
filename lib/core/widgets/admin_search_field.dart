// شريط بحث مشترك لشاشات الإدارة (إدارة الإعلانات / إدارة الحجوزات).
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// هل أي حقل من [fields] بيطابق [query]؟
/// - بحث نصي عادي (من غير حساسية لحالة الأحرف).
/// - لو المكتوب أرقام (3 أو أكتر) بنقارن بالأرقام بس، فرقم الهاتف يتلاقى
///   حتى لو مكتوب بمسافات أو شرطات أو +20.
bool matchesQuery(String query, Iterable<String> fields) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
  final digitsOnly = qDigits.length >= 3 && qDigits.length == q.replaceAll(RegExp(r'[\s\-+]'), '').length;
  for (final f in fields) {
    final t = f.toLowerCase();
    if (t.contains(q)) return true;
    if (digitsOnly && t.replaceAll(RegExp(r'[^0-9]'), '').contains(qDigits)) {
      return true;
    }
  }
  return false;
}

class AdminSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const AdminSearchField(
      {super.key, required this.hint, required this.onChanged});

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.icon, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                onChanged: (v) {
                  setState(() {}); // علامة X
                  widget.onChanged(v);
                },
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 15.5, color: AppColors.title),
                decoration: InputDecoration.collapsed(
                  hintText: widget.hint,
                  hintStyle:
                      TextStyle(fontSize: 14.5, color: AppColors.subtitle),
                ),
              ),
            ),
            if (_ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  setState(() {});
                  widget.onChanged('');
                },
                child:
                    Icon(Icons.close_rounded, color: AppColors.icon, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}
