// Data: الحجوزات على Supabase (RPC: my_bookings / book_car / remove_booking / clear_bookings).
// السيرفر هو اللي بيتحقق: السيارة متاحة، العرض أقل من السعر، ومفيش حجز مكرر.
import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/car.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class SupabaseBookingsRepository implements BookingsRepository {
  final ApiClient _client;
  const SupabaseBookingsRepository(this._client);

  static List<Booking> _parse(Object? json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((m) => BookingModel.fromJson(Map<String, dynamic>.from(m)).toEntity())
        .toList();
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw mapToFailure(e);
    }
  }

  @override
  Future<List<Booking>> getBookings() => _guard(() async =>
      _parse(await _client.post('/rest/v1/rpc/my_bookings', body: const {})));

  @override
  Future<List<Booking>> book(Car car, {int? offerPrice}) => _guard(() async =>
      _parse(await _client.post('/rest/v1/rpc/book_car', body: {
        'p_car_id': car.id,
        if (offerPrice != null) 'p_offer': offerPrice,
      })));

  @override
  Future<List<Booking>> remove(String carId) => _guard(() async => _parse(
      await _client.post('/rest/v1/rpc/remove_booking', body: {'p_car_id': carId})));

  @override
  Future<void> clear() => _guard(
      () => _client.post('/rest/v1/rpc/clear_bookings', body: const {}));
}
