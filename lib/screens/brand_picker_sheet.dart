import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';
import 'car_brand.dart';

/// يفتح نافذة "جميع ماركات السيارات المعتمدة".
/// بترجّع الماركة اللي المستخدم اختارها، أو null لو قفل النافذة.
Future<CarBrand?> showBrandPickerSheet(
    BuildContext context, {
      CarBrand? selected,
      Map<String, int> brandCounts = const {},
    }) {
  return showModalBottomSheet<CarBrand>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: ThemeController.barrierColor,
    builder: (_) =>
        BrandPickerSheet(selected: selected, brandCounts: brandCounts),
  );
}

class BrandPickerSheet extends StatefulWidget {
  final CarBrand? selected;

  /// عدد السيارات المتاحة لكل اسم ماركة (جاي من الـ Cubit مش من داتا ثابتة)
  final Map<String, int> brandCounts;
  const BrandPickerSheet({
    super.key,
    this.selected,
    this.brandCounts = const {},
  });

  @override
  State<BrandPickerSheet> createState() => _BrandPickerSheetState();
}

class _BrandPickerSheetState extends State<BrandPickerSheet> {
  final _searchCtrl = TextEditingController();
  late final Future<List<CarBrand>> _future = CarBrand.loadAll();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _availableCount(CarBrand b) => widget.brandCounts.entries
      .where((e) => b.matches(e.key))
      .fold<int>(0, (sum, e) => sum + e.value);

  /// تطبيع بسيط للحروف العربية عشان البحث يشتغل صح
  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim();

  /// أول كلمة من الاسم بعد التطبيع — لو الاسم من كلمتين نعتمد على الأولى بس
  String _firstWord(String s) {
    final parts = _norm(s).split(RegExp(r'[\s\-]+'));
    return parts.isEmpty ? '' : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: FutureBuilder<List<CarBrand>>(
        future: _future,
        builder: (context, snap) {
          final all = snap.data ?? const <CarBrand>[];
          final q = _norm(_query);
          final shown = q.isEmpty
              ? all
              : all.where((b) {
            final ar = _norm(b.nameAr);
            final en = _norm(b.nameEn);
            // ✅ يعتمد على أول كلمة: كتابة "أ" تظهر أستون مارتن وأوبل...
            //    لكن ماتظهرش "جي أي سي" لأن أول كلمة فيها "جي" مش "أي"
            return _firstWord(ar).startsWith(q) ||
                ar.startsWith(q) ||
                _firstWord(en).startsWith(q) ||
                en.startsWith(q);
          }).toList();

          return Column(
            children: [
              _buildHeader(all.length),
              _buildSearch(),
              Expanded(child: _buildBody(snap, shown)),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _buildHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.tone(0xFFF1F6FF), AppColors.tone(0xFFF9FBFE)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // يمين: أيقونة السيارة
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.directions_car_filled_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ FittedBox يمنع الـ overflow الأفقي للعنوان الطويل
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'جميع ماركات السيارات المعتمدة',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر أي ماركة سيارة للتصفية الفورية باللوجو الرسمي'
                      '${total > 0 ? ' ($total ماركة)' : ''}',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // شمال: زر الإغلاق
          Material(
            color: AppColors.tone(0xFFE9EEF5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.close_rounded,
                    color: AppColors.title, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- search
  Widget _buildSearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.tone(0xFFF7F9FC),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.tone(0xFFEDF1F6)),
        ),
      ),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.icon, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 16, color: AppColors.title),
                decoration: InputDecoration.collapsed(
                  hintText: 'ابحث باسم الماركة (مثال: تويوتا، مرسيدس، BMW...)',
                  hintStyle: TextStyle(fontSize: 14.5, color: AppColors.hint),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Icon(Icons.cancel_rounded,
                    color: AppColors.hint, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- body
  Widget _buildBody(AsyncSnapshot<List<CarBrand>> snap, List<CarBrand> shown) {
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.8));
    }
    if (snap.hasError) {
      debugPrint('BrandPicker: فشل تحميل $kBrandsJsonAsset -> ${snap.error}');
      return const _Message(
        icon: Icons.error_outline_rounded,
        text: 'تعذّر تحميل الماركات',
      );
    }
    if (shown.isEmpty) {
      return const _Message(
        icon: Icons.search_off_rounded,
        text: 'مفيش ماركة بالاسم ده',
      );
    }

    final bottom = MediaQuery.of(context).padding.bottom;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        // ✅ زودنا الارتفاع الثابت عشان المحتوى يبقى مرتاح جواه
        mainAxisExtent: 222,
      ),
      itemCount: shown.length,
      itemBuilder: (_, i) {
        final b = shown[i];
        return _BrandCard(
          brand: b,
          available: _availableCount(b),
          selected: b == widget.selected,
          onTap: () => Navigator.of(context).pop(b),
        );
      },
    );
  }
}

// =============================================================================
class _BrandCard extends StatelessWidget {
  final CarBrand brand;
  final int available;
  final bool selected;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brand,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  Widget _logo() {
    final fallback = Icon(Icons.directions_car_filled_outlined,
        color: AppColors.icon, size: 28);
    if (brand.logoUrl.isEmpty) return fallback;
    return Image.network(
      brand.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.tone(0xFFDDE5EF),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Column(
            // ✅ محتوى الكارت كله في المنتصف (الصورة والأسماء والشيبس)
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                // ✅ صغّرنا اللوجو شوية (56 بدل 64)
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, // خلفية اللوجو بيضا حتى في الوضع الداكن
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _logo(),
              ),
              const SizedBox(height: 10),
              // ✅ FittedBox + Flexible: الاسم الطويل بيتصغّر بدل ما يعمل overflow
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    brand.nameAr,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ),
              ),
              if (brand.nameEn.isNotEmpty)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      brand.nameEn,
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.hint,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              // ✅ FittedBox حوالين الـ Wrap: الشيبس مهما اتجمعت مبتعملش overflow أفقي
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (brand.countryAr.isNotEmpty)
                      _Chip(text: brand.countryAr),
                    if (available > 0)
                      _Chip(
                        text: '$available متوفر',
                        bg: AppColors.tone(0xFFDCFCE7),
                        fg: AppColors.tone(0xFF166534),
                        bold: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  final bool bold;

  const _Chip({
    required this.text,
    this.bg,
    this.fg,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ padding أصغر شوية
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? AppColors.tone(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: fg ?? AppColors.subtitle,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.icon),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
        ],
      ),
    );
  }
}