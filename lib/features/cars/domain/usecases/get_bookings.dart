// Domain: حالة استخدام — قراءة الحجوزات
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class GetBookings {
  final BookingsRepository _repository;
  const GetBookings(this._repository);

  Future<List<Booking>> call() => _repository.getBookings();
}
