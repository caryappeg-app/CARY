// Data: تطبيق BookingsRepository
import '../../../../core/error/failure.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/car.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_local_data_source.dart';
import '../models/booking_model.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsLocalDataSource _local;
  const BookingsRepositoryImpl(this._local);

  Future<List<Booking>> _read() async {
    try {
      return (await _local.read()).map((m) => m.toEntity()).toList();
    } catch (_) {
      throw const CacheFailure();
    }
  }

  @override
  Future<List<Booking>> getBookings() => _read();

  @override
  Future<List<Booking>> book(Car car, {int? offerPrice}) async {
    final list = await _read();
    final existing = list.where((b) => b.car.id == car.id).toList();
    // حجز عادي (بدون عرض) على سيارة ليها عرض قديم: نحتفظ بالعرض القديم
    final effectiveOffer =
        offerPrice ?? (existing.isEmpty ? null : existing.first.offerPrice);

    list.removeWhere((b) => b.car.id == car.id);
    list.insert(0, Booking(car: car, offerPrice: effectiveOffer));
    await _local.write(list.map(BookingModel.fromEntity).toList());
    return list;
  }

  @override
  Future<List<Booking>> remove(String carId) async {
    final list = await _read();
    list.removeWhere((b) => b.car.id == carId);
    await _local.write(list.map(BookingModel.fromEntity).toList());
    return list;
  }

  @override
  Future<void> clear() => _local.write(const []);
}
