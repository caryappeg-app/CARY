// Presentation: منطق شاشة السيارات (بحث + فلاتر + ترتيب + Pagination + كاش في الذاكرة)
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../domain/entities/car_filter.dart';
import '../../domain/entities/car_sort.dart';
import '../../domain/usecases/get_brand_counts.dart';
import '../../domain/usecases/get_cars.dart';
import 'cars_state.dart';

class CarsCubit extends Cubit<CarsState> {
  static const int pageSize = 6;

  final GetCars _getCars;
  final GetBrandCounts _getBrandCounts;

  // Debounce: البحث والموديل بيستنوا المستخدم يبطّل كتابة قبل ما يتبعت طلب
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 400));
  final Debouncer _modelDebouncer =
      Debouncer(delay: const Duration(milliseconds: 400));

  int _requestId = 0; // عشان نتجاهل ردود الطلبات القديمة

  CarsCubit({
    required GetCars getCars,
    required GetBrandCounts getBrandCounts,
  })  : _getCars = getCars,
        _getBrandCounts = getBrandCounts,
        super(const CarsState());

  /// أول تحميل — لو الداتا موجودة بالفعل (رجعنا للشاشة) مبنعيدش الطلب
  Future<void> load() async {
    if (state.status != CarsStatus.initial) return;
    _loadBrandCounts();
    await _fetchFirstPage();
  }

  Future<void> refresh() {
    _loadBrandCounts();
    return _fetchFirstPage(forceRefresh: true);
  }

  // ---------------------------------------------------------------- فلاتر
  void search(String text) => _searchDebouncer(() {
        final clean = InputSanitizer.searchQuery(text); // تنظيف + حد أقصى للطول
        if (clean == state.filter.query.trim()) return;
        _applyFilter(state.filter.copyWith(query: clean));
      });

  void setModel(String text) => _modelDebouncer(() {
        final clean = InputSanitizer.searchQuery(text);
        if (clean == state.filter.model.trim()) return;
        _applyFilter(state.filter.copyWith(model: clean));
      });

  void setBrandNames(List<String> names) =>
      _applyFilter(state.filter.copyWith(brandNames: names));

  void setYearFrom(int? v) => _applyFilter(state.filter.copyWith(yearFrom: v));
  void setYearTo(int? v) => _applyFilter(state.filter.copyWith(yearTo: v));
  void setPriceFrom(int? v) =>
      _applyFilter(state.filter.copyWith(priceFrom: v));
  void setPriceTo(int? v) => _applyFilter(state.filter.copyWith(priceTo: v));
  void setSort(CarSort sort) => _applyFilter(state.filter.copyWith(sort: sort));

  void resetFilters() {
    _searchDebouncer.cancel();
    _modelDebouncer.cancel();
    _applyFilter(const CarFilter());
  }

  void _applyFilter(CarFilter filter) {
    emit(state.copyWith(filter: filter));
    _fetchFirstPage();
  }

  // ------------------------------------------------------------ Pagination
  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status == CarsStatus.loading) {
      return;
    }
    final id = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final res = await _getCars(
        filter: state.filter,
        page: state.page + 1,
        pageSize: pageSize,
      );
      if (isClosed || id != _requestId) return; // الفلتر اتغير أثناء التحميل
      emit(state.copyWith(
        cars: [...state.cars, ...res.items],
        page: res.page,
        total: res.total,
        hasMore: res.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      if (isClosed || id != _requestId) return;
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  // -------------------------------------------------------------- Internals
  Future<void> _fetchFirstPage({bool forceRefresh = false}) async {
    final id = ++_requestId;
    // بنسيب القايمة القديمة ظاهرة لحد ما النتايج الجديدة توصل (من غير وميض)
    emit(state.copyWith(
      status: CarsStatus.loading,
      isLoadingMore: false,
      clearError: true,
    ));
    try {
      final res = await _getCars(
        filter: state.filter,
        page: 1,
        pageSize: pageSize,
        forceRefresh: forceRefresh,
      );
      if (isClosed || id != _requestId) return;
      emit(state.copyWith(
        status: CarsStatus.success,
        cars: res.items,
        page: res.page,
        total: res.total,
        hasMore: res.hasMore,
      ));
    } catch (e) {
      if (isClosed || id != _requestId) return;
      // أي استثناء خام بيتحوّل لـ Failure برسالة عربية آمنة (مفيش تفاصيل تقنية للمستخدم)
      emit(state.copyWith(
        status: CarsStatus.failure,
        error: mapToFailure(e).message,
      ));
    }
  }

  Future<void> _loadBrandCounts() async {
    try {
      final counts = await _getBrandCounts();
      if (!isClosed) emit(state.copyWith(brandCounts: counts));
    } catch (_) {
      // مش حرج: العدّاد في نافذة الماركات بس
    }
  }

  @override
  Future<void> close() {
    _searchDebouncer.dispose();
    _modelDebouncer.dispose();
    return super.close();
  }
}
