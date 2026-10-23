// Domain: حالة استخدام — مسح كل المفضلات
import '../repositories/favorites_repository.dart';

class ClearFavorites {
  final FavoritesRepository _repository;
  const ClearFavorites(this._repository);

  Future<void> call() => _repository.clear();
}
