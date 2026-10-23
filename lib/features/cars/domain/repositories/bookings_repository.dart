// Domain: عقد الحجوزات
import '../entities/booking.dart';
import '../entities/car.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getBookings();

  /// بيحجز السيارة (لو محجوزة قبل كده بتتنقل لأول القايمة)،
  /// ولو فيه [offerPrice] بيتسجل مع الحجز
  Future<List<Booking>> book(Car car, {int? offerPrice});

  /// بيحذف حجز سيارة واحدة ويرجّع القايمة الجديدة
  Future<List<Booking>> remove(String carId);

  Future<void> clear();
}
