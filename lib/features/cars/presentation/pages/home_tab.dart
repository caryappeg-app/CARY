// Presentation: تاب الرئيسية (بحث + فلاتر + ترتيب + قايمة السيارات)
// الحالة كلها في CarsCubit؛ الويدجت هنا بيعرض بس ويبعت الأحداث.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../screens/brand_picker_sheet.dart';
import '../../../../screens/car_brand.dart';
import '../../../../screens/field_tile.dart';
import '../../../home/presentation/widgets/app_top_bar.dart';
import '../../domain/entities/car_filter.dart';
import '../../domain/entities/car_sort.dart';
import '../cubit/cars_cubit.dart';
import '../cubit/cars_state.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/car_card.dart';
import '../widgets/car_sort_label.dart';
import '../widgets/filter_picks.dart';
import 'open_car_details.dart';

class HomeTab extends StatefulWidget {
  /// بتتنادى بعد تأكيد حجز سيارة (الشاشة الرئيسية بتنقل لتاب حجوزاتي)
  final VoidCallback onBooked;

  /// بيتنادى لما المستخدم يضغط على أيقونة "الرئيسية" وهي مفتوحة:
  /// نرجع لأول القايمة ونحدّث النتايج
  final Listenable? reselectSignal;

  const HomeTab({super.key, required this.onBooked, this.reselectSignal});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // السنة الحالية بتتحسب تلقائي (مش ثابتة) عشان القايمة متقدّمش في الزمن
  static final _years = [for (var y = DateTime.now().year; y >= 1980; y--) y];
  static const _prices = [
    100000, 200000, 300000, 400000, 500000,
    600000, 700000, 800000, 900000, 1000000,
    1100000, 1200000, 1300000, 1400000, 1500000,
    1600000, 1700000, 1800000, 1900000, 2000000,
    2100000, 2200000, 2300000, 2400000, 2500000,
    2600000, 2700000, 2800000, 2900000, 3000000,
    3100000, 3200000, 3300000, 3400000, 3500000,
    3600000, 3700000, 3800000, 3900000, 4000000,
    4100000, 4200000, 4300000, 4400000, 4500000,
    4600000, 4700000, 4800000, 4900000, 5000000,
  ];

  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();
  final _searchCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  CarBrand? _brand; // الماركة المختارة (للعرض) — الفلتر الفعلي في الـ Cubit
  bool _showFilters = true;

  CarsCubit get _cubit => context.read<CarsCubit>();
  CarFilter get _filter => _cubit.state.filter;
  int? get _yearFrom => _filter.yearFrom;
  int? get _yearTo => _filter.yearTo;
  int? get _priceFrom => _filter.priceFrom;
  int? get _priceTo => _filter.priceTo;
  CarSort get _sort => _filter.sort;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.reselectSignal?.addListener(_onReselect);
  }

  void _onReselect() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
    _cubit.refresh(); // الفلاتر الحالية بتفضل زي ما هي
  }

  @override
  void dispose() {
    widget.reselectSignal?.removeListener(_onReselect);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  /// Lazy loading: لما نقرّب من آخر القايمة نحمّل الصفحة اللي بعدها
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) _cubit.loadMore();
  }

  Future<void> _pickBrand() async {
    FocusScope.of(context).unfocus();
    final cubit = _cubit;
    final picked = await showBrandPickerSheet(
      context,
      selected: _brand,
      brandCounts: cubit.state.brandCounts,
    );
    if (picked != null && mounted) {
      setState(() => _brand = picked);
      cubit.setBrandNames([picked.nameAr, picked.nameEn]);
    }
  }

  void _clearBrand() {
    setState(() => _brand = null);
    _cubit.setBrandNames(const []);
  }

  void _resetFilters() {
    _searchCtrl.clear();
    _modelCtrl.clear();
    setState(() => _brand = null);
    _cubit.resetFilters();
  }

  void _scrollToResults() {
    FocusScope.of(context).unfocus();
    final ctx = _resultsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openAllFilters() {
    setState(() => _showFilters = true);
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesCubit>().state;

    return BlocBuilder<CarsCubit, CarsState>(
      builder: (context, state) {
        final results = state.cars;
        final count = state.total;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(child: AppTopBar()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 14),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: _showFilters
                            ? _buildFilterPanel(count)
                            : const SizedBox(width: double.infinity),
                      ),
                      SizedBox(height: _showFilters ? 18 : 4),
                      _buildResultsHeader(count),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (state.isInitialLoading)
                const SliverToBoxAdapter(child: _LoadingIndicator())
              else if (state.status == CarsStatus.failure && results.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildError(state.error),
                  ),
                )
              else if (results.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildEmpty(),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final car = results[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: CarCard(
                            car: car,
                            isFavorite: favorites.isFavorite(car.id),
                            onFavorite: () =>
                                context.read<FavoritesCubit>().toggle(car),
                            onDetails: () => openCarDetails(
                              context,
                              car,
                              onBooked: widget.onBooked,
                            ),
                          ),
                        );
                      },
                      childCount: results.length,
                    ),
                  ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(child: _LoadingIndicator()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          IconButton(
            tooltip: 'الفلاتر',
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(Icons.tune_rounded,
                color: AppColors.blue, size: 28),
          ),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _cubit.search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _scrollToResults(),
              style: TextStyle(fontSize: 16, color: AppColors.title),
              decoration: InputDecoration.collapsed(
                hintText: 'ابحث بالماركة، الموديل، أو الفئة...',
                hintStyle: TextStyle(fontSize: 15.5, color: AppColors.subtitle),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search, color: AppColors.icon, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(int count) {
    Widget pair(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.fieldBorder)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'أو ابحث بواسطة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.fieldBorder)),
            ],
          ),
          const SizedBox(height: 18),
          pair(
            BrandPick(
              brand: _brand,
              onTap: _pickBrand,
              onClear: _clearBrand,
            ),
            _buildModelField(),
          ),
          const SizedBox(height: 10),
          pair(
            FilterPick<int>(
              icon: Icons.calendar_month_outlined,
              label: 'من سنة',
              hint: 'اختر السنة',
              value: _yearFrom,
              items: _years,
              labelOf: (y) => '$y',
              onChanged: _cubit.setYearFrom,
            ),
            FilterPick<int>(
              icon: Icons.event_available_outlined,
              label: 'حتى سنة',
              hint: 'اختر السنة',
              value: _yearTo,
              items: _years,
              labelOf: (y) => '$y',
              onChanged: _cubit.setYearTo,
            ),
          ),
          const SizedBox(height: 10),
          pair(
            FilterPick<int>(
              icon: Icons.payments_outlined,
              label: 'السعر من',
              hint: 'اختر السعر',
              value: _priceFrom,
              items: _prices,
              labelOf: formatNumber,
              onChanged: _cubit.setPriceFrom,
            ),
            FilterPick<int>(
              icon: Icons.price_check_rounded,
              label: 'السعر إلى',
              hint: 'اختر السعر',
              value: _priceTo,
              items: _prices,
              labelOf: formatNumber,
              onChanged: _cubit.setPriceTo,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _scrollToResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.blue.withOpacity(0.35),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'عرض السيارات المتاحة ($count)',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelField() {
    return FieldTile(
      icon: Icons.history_toggle_off_rounded,
      label: 'الموديل',
      highlighted: _modelCtrl.text.trim().isNotEmpty,
      child: TextField(
        controller: _modelCtrl,
        onChanged: (v) {
          setState(() {}); // تحديث تمييز خانة الموديل
          _cubit.setModel(v);
        },
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _scrollToResults(),
        maxLines: 1,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.title),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'اكتب الموديل',
          hintMaxLines: 1,
          hintStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.hint,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      key: _resultsKey,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _openAllFilters,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.title, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'كل الفلاتر',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: PopupMenuButton<CarSort>(
            tooltip: 'الترتيب',
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: _cubit.setSort,
            itemBuilder: (_) => [
              for (final s in CarSort.values)
                PopupMenuItem<CarSort>(
                  value: s,
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontWeight:
                      s == _sort ? FontWeight.w800 : FontWeight.w500,
                      color: s == _sort ? AppColors.blue : AppColors.title,
                    ),
                  ),
                ),
            ],
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'الترتيب: ${_sort.label}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.sort_rounded,
                    color: AppColors.icon,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count سيارة\nمتوفرة',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: AppColors.icon),
          const SizedBox(height: 12),
          Text(
            'مفيش سيارات مطابقة للبحث',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'مسح الفلاتر',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String? message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.icon),
          const SizedBox(height: 12),
          Text(
            message ?? 'حصل خطأ أثناء تحميل السيارات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _cubit.refresh,
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشر تحميل صغير (أول تحميل / تحميل صفحة جديدة)
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }
}