// Domain: حالة استخدام — حذف حجز سيارة واحدة من حجوزاتي
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class RemoveBooking {
  final BookingsRepository _repository;
  const RemoveBooking(this._repository);

  Future<List<Booking>> call(String carId) => _repository.remove(carId);
}
