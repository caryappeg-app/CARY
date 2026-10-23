// Data: تطبيق CarRepository — بيجرّب الكاش المحلي الأول وبعدين الـ Remote
import '../../../../core/error/error_mapper.dart';
import '../../../../core/paging/paged_result.dart';
import '../../domain/entities/car.dart';
import '../../domain/entities/car_filter.dart';
import '../../domain/entities/car_rules.dart';
import '../../domain/repositories/car_repository.dart';
import '../datasources/car_local_data_source.dart';
import '../datasources/car_remote_data_source.dart';
import '../models/car_model.dart';

class CarRepositoryImpl implements CarRepository {
  final CarRemoteDataSource _remote;
  final CarLocalDataSource _local;

  const CarRepositoryImpl({
    required CarRemoteDataSource remote,
    required CarLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<PagedResult<Car>> getCars({
    required CarFilter filter,
    required int page,
    required int pageSize,
    bool forceRefresh = false,
  }) async {
    // تحديث إجباري للصفحة الأولى = نمسح الكاش كله (عشان صفحات تانية قديمة ما تتلخبطش)
    if (forceRefresh && page == 1) await _local.clear();
    final key = '${filter.cacheKey}|$page|$pageSize';

    CarsPageModel? model = forceRefresh ? null : await _local.getCachedPage(key);
    if (model == null) {
      try {
        model = await _remote.fetchCars(
            filter: filter, page: page, pageSize: pageSize);
        await _local.cachePage(key, model);
      } catch (e) {
        // أوفلاين / فشل الشبكة: لو عندنا نسخة قديمة نعرضها بدل ما نفشل
        model = await _local.getCachedPage(key);
        if (model == null) throw mapToFailure(e); // رسالة آمنة بس
      }
    }

    final CarsPageModel data = model!;
    return PagedResult<Car>(
      items: data.items
          .map((m) => m.toEntity())
          .where(CarRules.isValid) // نتجاهل أي سجل بيانات غلط
          .toList(),
      page: page,
      total: data.total,
      hasMore: page * pageSize < data.total,
    );
  }

  @override
  Future<Car?> getCarById(String id) async {
    try {
      final m = await _remote.fetchCarById(id);
      final car = m?.toEntity();
      return (car != null && CarRules.isValid(car)) ? car : null;
    } catch (e) {
      throw mapToFailure(e);
    }
  }

  @override
  Future<Map<String, int>> getBrandCounts() async {
    final cached = await _local.getCachedBrandCounts();
    if (cached != null) return cached;
    try {
      final fresh = await _remote.fetchBrandCounts();
      await _local.cacheBrandCounts(fresh);
      return fresh;
    } catch (e) {
      throw mapToFailure(e);
    }
  }
}
