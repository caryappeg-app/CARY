// Domain: حالة استخدام — إضافة/إزالة سيارة من المفضلة
import '../entities/car.dart';
import '../repositories/favorites_repository.dart';

class ToggleFavorite {
  final FavoritesRepository _repository;
  const ToggleFavorite(this._repository);

  Future<List<Car>> call(Car car) => _repository.toggle(car);
}
