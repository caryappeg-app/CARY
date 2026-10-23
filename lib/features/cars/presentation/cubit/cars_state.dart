// Presentation: حالة قايمة السيارات (محفوظة في الـ Cubit فمبتتحمّلش تاني عند التنقل)
import '../../domain/entities/car.dart';
import '../../domain/entities/car_filter.dart';

enum CarsStatus { initial, loading, success, failure }

class CarsState {
  final CarsStatus status;
  final List<Car> cars; // السيارات المحمّلة لحد دلوقتي (كل الصفحات)
  final CarFilter filter;
  final int page; // آخر صفحة اتحمّلت
  final int total; // إجمالي النتايج المطابقة
  final bool hasMore;
  final bool isLoadingMore;
  final Map<String, int> brandCounts;
  final String? error;

  const CarsState({
    this.status = CarsStatus.initial,
    this.cars = const [],
    this.filter = const CarFilter(),
    this.page = 0,
    this.total = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.brandCounts = const {},
    this.error,
  });

  bool get isInitialLoading =>
      (status == CarsStatus.initial || status == CarsStatus.loading) &&
      cars.isEmpty;

  CarsState copyWith({
    CarsStatus? status,
    List<Car>? cars,
    CarFilter? filter,
    int? page,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    Map<String, int>? brandCounts,
    String? error,
    bool clearError = false,
  }) {
    return CarsState(
      status: status ?? this.status,
      cars: cars ?? this.cars,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      brandCounts: brandCounts ?? this.brandCounts,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
