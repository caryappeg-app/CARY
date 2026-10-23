// Data: مصدر السيارات الحقيقي عبر ApiClient (REST / Supabase REST).
// جاهز للتفعيل: بدّل MockCarRemoteDataSource بيه في core/di/injection.dart.
// عدّل أسماء الـ endpoints والـ query params هنا بس لو الـ Backend مختلف.
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../domain/entities/car_filter.dart';
import '../models/car_model.dart';
import 'car_remote_data_source.dart';

class ApiCarRemoteDataSource implements CarRemoteDataSource {
  final ApiClient _client;
  const ApiCarRemoteDataSource(this._client);

  @override
  Future<CarsPageModel> fetchCars({
    required CarFilter filter,
    required int page,
    required int pageSize,
  }) async {
    final json = await _client.get('/cars', query: {
      'page': page,
      'page_size': pageSize,
      // Query params بتتبعت مفصولة (مش مدمجة في SQL) => مفيش Injection؛ و escapeLike لو السيرفر بيستخدم ILIKE
      if (filter.query.trim().isNotEmpty)
        'q': InputSanitizer.escapeLike(InputSanitizer.searchQuery(filter.query)),
      if (filter.model.trim().isNotEmpty)
        'model': InputSanitizer.escapeLike(InputSanitizer.searchQuery(filter.model)),
      if (filter.brandNames.isNotEmpty) 'brands': filter.brandNames.join(','),
      if (filter.yearFrom != null) 'year_from': filter.yearFrom,
      if (filter.yearTo != null) 'year_to': filter.yearTo,
      if (filter.priceFrom != null) 'price_from': filter.priceFrom,
      if (filter.priceTo != null) 'price_to': filter.priceTo,
      'sort': filter.sort.name,
    });

    if (json is! Map<String, dynamic>) throw const ServerFailure();
    final items = (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => CarModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return CarsPageModel(
      items: items,
      total: InputSanitizer.nonNegativeInt(json['total']),
    );
  }

  @override
  Future<CarModel?> fetchCarById(String id) async {
    final json = await _client.get('/cars/${Uri.encodeComponent(id)}');
    if (json is! Map) return null;
    return CarModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<Map<String, int>> fetchBrandCounts() async {
    final json = await _client.get('/cars/brand-counts');
    if (json is! Map<String, dynamic>) throw const ServerFailure();
    return json.map((k, v) =>
        MapEntry(InputSanitizer.text(k, maxLength: 60), InputSanitizer.nonNegativeInt(v)));
  }
}
