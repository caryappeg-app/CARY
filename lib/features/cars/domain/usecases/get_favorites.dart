// Domain: حالة استخدام — قراءة المفضلات
import '../entities/car.dart';
import '../repositories/favorites_repository.dart';

class GetFavorites {
  final FavoritesRepository _repository;
  const GetFavorites(this._repository);

  Future<List<Car>> call() => _repository.getFavorites();
}
