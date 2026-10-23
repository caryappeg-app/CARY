// Domain: عقد المفضلات
import '../entities/car.dart';

abstract class FavoritesRepository {
  Future<List<Car>> getFavorites();

  /// بيضيف السيارة للمفضلة أو بيشيلها، وبيرجّع القايمة بعد التعديل
  Future<List<Car>> toggle(Car car);

  Future<void> clear();
}
