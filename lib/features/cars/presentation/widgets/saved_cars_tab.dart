// Presentation: تاب مشترك (المفضلات + حجوزاتي): شريط بحث + زر "مسح" لتفريغ القايمة
import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/theme_controller.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../home/presentation/widgets/app_top_bar.dart';
import '../../../home/presentation/widgets/soon_tab.dart';
import '../../domain/entities/car.dart';

/// تاب مشترك (المفضلات + حجوزاتي): شريط بحث + زر "مسح" لتفريغ القائمة
class SavedCarsTab extends StatefulWidget {
  final List<Car> cars;
  final String searchHint;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String clearTitle;
  final String clearMessage;
  final VoidCallback onClear;
  final Widget Function(BuildContext context, Car car) cardBuilder;

  const SavedCarsTab({
    required this.cars,
    required this.searchHint,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.clearTitle,
    required this.clearMessage,
    required this.onClear,
    required this.cardBuilder,
  });

  @override
  State<SavedCarsTab> createState() => _SavedCarsTabState();
}

class _SavedCarsTabState extends State<SavedCarsTab> {
  final _search = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _query = ''; // النص المعتمد بعد الـ debounce

  @override
  void dispose() {
    _debouncer.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Car> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.cars;
    return widget.cars.where((c) {
      final hay =
          '${c.brand} ${c.model} ${c.year} ${c.bodyType} ${c.transmission} ${c.title}'
              .toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _confirmClear() async {
    FocusScope.of(context).unfocus();
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: ThemeController.barrierColor,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          widget.clearTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.title),
        ),
        content: Text(
          widget.clearMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 15, height: 1.6, color: AppColors.subtitle),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('مسح',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      _search.clear();
      _debouncer.cancel();
      setState(() => _query = '');
      widget.onClear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cars.isEmpty) {
      return SoonTab(
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
        icon: widget.emptyIcon,
      );
    }

    final results = _filtered;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      children: [
        const AppTopBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 10),
              _buildClearButton(),
            ],
          ),
        ),
        if (results.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 40, 16, 24),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.icon),
                SizedBox(height: 10),
                Text(
                  'مفيش نتائج مطابقة للبحث',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              children: [
                for (final car in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: widget.cardBuilder(context, car),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.icon, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) {
                setState(() {}); // علامة X
                _debouncer(() {
                  if (mounted) setState(() => _query = v);
                });
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 16, color: AppColors.title),
              decoration: InputDecoration.collapsed(
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                    fontSize: 15.5, color: AppColors.subtitle),
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _search.clear();
                _debouncer.cancel();
                _query = '';
              }),
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child:
                    Icon(Icons.close_rounded, color: AppColors.icon, size: 22),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return Material(
      color: AppColors.errorBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _confirmClear,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.errorBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_sweep_outlined,
                  color: AppColors.error, size: 26),
              SizedBox(width: 6),
              Text(
                'مسح',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.errorText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
