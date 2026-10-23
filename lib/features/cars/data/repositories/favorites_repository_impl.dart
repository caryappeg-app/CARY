// Data: تطبيق FavoritesRepository
import '../../../../core/error/failure.dart';
import '../../domain/entities/car.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/saved_cars_local_data_source.dart';
import '../models/car_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final SavedCarsLocalDataSource _local;
  const FavoritesRepositoryImpl(this._local);

  Future<List<Car>> _read() async {
    try {
      return (await _local.read()).map((m) => m.toEntity()).toList();
    } catch (_) {
      throw const CacheFailure();
    }
  }

  @override
  Future<List<Car>> getFavorites() => _read();

  @override
  Future<List<Car>> toggle(Car car) async {
    final list = await _read();
    final exists = list.any((c) => c.id == car.id);
    if (exists) {
      list.removeWhere((c) => c.id == car.id);
    } else {
      list.add(car);
    }
    await _local.write(list.map(CarModel.fromEntity).toList());
    return list;
  }

  @override
  Future<void> clear() => _local.write(const []);
}
