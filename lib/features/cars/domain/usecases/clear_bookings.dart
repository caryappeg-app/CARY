// Domain: حالة استخدام — مسح كل الحجوزات
import '../repositories/bookings_repository.dart';

class ClearBookings {
  final BookingsRepository _repository;
  const ClearBookings(this._repository);

  Future<void> call() => _repository.clear();
}
