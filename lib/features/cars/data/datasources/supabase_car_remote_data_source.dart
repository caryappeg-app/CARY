// Data: السيارات من Supabase (PostgREST).
// - البحث/الفلترة/الترتيب/الصفحات: RPC `search_cars` (بيرجّع { items, total }).
// - سيارة واحدة: view `cars_public`. - عدد كل ماركة: RPC `brand_counts`.
// الداتا بترجع بنفس مفاتيح CarModel.fromJson بالظبط.
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../domain/entities/car_filter.dart';
import '../models/car_model.dart';
import 'car_remote_data_source.dart';

class SupabaseCarRemoteDataSource implements CarRemoteDataSource {
  final ApiClient _client;
  const SupabaseCarRemoteDataSource(this._client);

  @override
  Future<CarsPageModel> fetchCars({
    required CarFilter filter,
    required int page,
    required int pageSize,
  }) async {
    final json = await _client.post('/rest/v1/rpc/search_cars', body: {
      'p_page': page,
      'p_page_size': pageSize,
      'p_sort': filter.sort.name,
      // escapeLike: الداتابيز بتستخدم ILIKE بـ \ كرمز هروب
      if (filter.query.trim().isNotEmpty)
        'p_q': InputSanitizer.escapeLike(InputSanitizer.searchQuery(filter.query)),
      if (filter.model.trim().isNotEmpty)
        'p_model':
            InputSanitizer.escapeLike(InputSanitizer.searchQuery(filter.model)),
      if (filter.brandNames.isNotEmpty) 'p_brands': filter.brandNames.join(','),
      if (filter.yearFrom != null) 'p_year_from': filter.yearFrom,
      if (filter.yearTo != null) 'p_year_to': filter.yearTo,
      if (filter.priceFrom != null) 'p_price_from': filter.priceFrom,
      if (filter.priceTo != null) 'p_price_to': filter.priceTo,
    });

    if (json is! Map) throw const ServerFailure();
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
    final json = await _client.get('/rest/v1/cars_public', query: {
      'id': 'eq.$id',
      'limit': 1,
    });
    if (json is! List || json.isEmpty || json.first is! Map) return null;
    return CarModel.fromJson(Map<String, dynamic>.from(json.first as Map));
  }

  @override
  Future<Map<String, int>> fetchBrandCounts() async {
    final json = await _client.post('/rest/v1/rpc/brand_counts', body: const {});
    if (json is! Map) throw const ServerFailure();
    return json.map((k, v) => MapEntry(
        InputSanitizer.text(k, maxLength: 60), InputSanitizer.nonNegativeInt(v)));
  }
}
