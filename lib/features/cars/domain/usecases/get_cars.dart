// Domain: حالة استخدام — جلب صفحة من السيارات
import '../../../../core/paging/paged_result.dart';
import '../entities/car.dart';
import '../entities/car_filter.dart';
import '../repositories/car_repository.dart';

class GetCars {
  final CarRepository _repository;
  const GetCars(this._repository);

  Future<PagedResult<Car>> call({
    required CarFilter filter,
    required int page,
    int pageSize = 6,
    bool forceRefresh = false,
  }) =>
      _repository.getCars(
        filter: filter,
        page: page,
        pageSize: pageSize,
        forceRefresh: forceRefresh,
      );
}
