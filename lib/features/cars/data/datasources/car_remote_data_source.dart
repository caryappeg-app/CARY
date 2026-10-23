// Data: عقد مصدر البيانات البعيد (Supabase / Firebase / REST API).
// لما تربط الداتابيز: اعمل class جديد بيطبّق الـ interface ده وبدّله في core/di/injection.dart
import '../../domain/entities/car_filter.dart';
import '../models/car_model.dart';

abstract class CarRemoteDataSource {
  Future<CarsPageModel> fetchCars({
    required CarFilter filter,
    required int page,
    required int pageSize,
  });

  Future<Map<String, int>> fetchBrandCounts();

  /// سيارة واحدة بالـ id (لفتح رابط المشاركة). null لو مش موجودة.
  Future<CarModel?> fetchCarById(String id);
}
