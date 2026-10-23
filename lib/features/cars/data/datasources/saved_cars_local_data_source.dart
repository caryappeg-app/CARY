// Data: تخزين محلي للقوايم اللي المستخدم بيحفظها (مفضلات / حجوزات).
// النسخة الحالية في الذاكرة؛ استبدلها بـ SharedPreferences / Hive / API لما تحب.
import '../models/car_model.dart';

abstract class SavedCarsLocalDataSource {
  Future<List<CarModel>> read();
  Future<void> write(List<CarModel> cars);
}

class InMemorySavedCarsLocalDataSource implements SavedCarsLocalDataSource {
  List<CarModel> _cars = const [];

  @override
  Future<List<CarModel>> read() async => List<CarModel>.of(_cars);

  @override
  Future<void> write(List<CarModel> cars) async =>
      _cars = List<CarModel>.of(cars);
}
