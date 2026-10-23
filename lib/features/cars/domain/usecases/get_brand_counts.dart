// Domain: حالة استخدام — عدد السيارات المتاحة لكل ماركة
import '../repositories/car_repository.dart';

class GetBrandCounts {
  final CarRepository _repository;
  const GetBrandCounts(this._repository);

  Future<Map<String, int>> call() => _repository.getBrandCounts();
}
