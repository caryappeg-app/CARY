// Data: مصدر تجريبي بيحاكي السيرفر (فلترة + ترتيب + Pagination + تأخير شبكة)
import '../../domain/entities/car.dart';
import '../../domain/entities/car_filter.dart';
import '../models/car_model.dart';
import 'car_mock_data.dart';
import 'car_remote_data_source.dart';

class MockCarRemoteDataSource implements CarRemoteDataSource {
  final Duration latency;

  /// سيارات إضافية بتتعرض في الرئيسية (إعلانات المستخدمين اللي اتقبلت)
  final List<Car> Function()? extraCars;

  /// ids سيارات تجريبية اتحذفت (مش بتتعرض)
  final Set<String> Function()? hiddenIds;

  const MockCarRemoteDataSource({
    this.latency = const Duration(milliseconds: 350),
    this.extraCars,
    this.hiddenIds,
  });

  List<CarModel> get _all => [
        // الإعلانات المقبولة الأول (الأحدث فوق)
        ...?extraCars?.call().map(CarModel.fromEntity),
        ...kMockCarsJson
            .where((j) => !(hiddenIds?.call() ?? const <String>{}).contains(j['id']))
            .map(CarModel.fromJson),
      ];

  @override
  Future<CarsPageModel> fetchCars({
    required CarFilter filter,
    required int page,
    required int pageSize,
  }) async {
    await Future<void>.delayed(latency);

    final matched = filter.sorted(
      _all.map((m) => m.toEntity()).where(filter.matches).toList(),
    );

    final start = (page - 1) * pageSize;
    final slice = start >= matched.length
        ? const <CarModel>[]
        : matched
            .skip(start)
            .take(pageSize)
            .map(CarModel.fromEntity)
            .toList();

    return CarsPageModel(items: slice, total: matched.length);
  }

  @override
  Future<CarModel?> fetchCarById(String id) async {
    await Future<void>.delayed(latency ~/ 2);
    for (final m in _all) {
      if (m.toEntity().id == id) return m;
    }
    return null;
  }

  @override
  Future<Map<String, int>> fetchBrandCounts() async {
    await Future<void>.delayed(latency ~/ 2);
    final counts = <String, int>{};
    for (final m in _all) {
      final brand = m.toEntity().brand;
      counts[brand] = (counts[brand] ?? 0) + 1;
    }
    return counts;
  }
}
