// Domain: عقد (Interface) بيحدد إزاي بنجيب السيارات — من غير ما نعرف المصدر
import '../../../../core/paging/paged_result.dart';
import '../entities/car.dart';
import '../entities/car_filter.dart';

abstract class CarRepository {
  /// صفحة من السيارات المطابقة للفلتر (Pagination)
  Future<PagedResult<Car>> getCars({
    required CarFilter filter,
    required int page,
    required int pageSize,
    bool forceRefresh = false,
  });

  /// سيارة بالـ id (لرابط المشاركة). null لو مش موجودة أو مش متاحة.
  Future<Car?> getCarById(String id);

  /// عدد السيارات المتاحة لكل ماركة (اسم الماركة -> العدد)
  Future<Map<String, int>> getBrandCounts();
}
