// Domain: حالة استخدام — حجز سيارة / طلب شراء (مع عرض سعر اختياري)
import '../../../../core/error/failure.dart';
import '../entities/booking.dart';
import '../entities/car.dart';
import '../entities/offer_rules.dart';
import '../repositories/bookings_repository.dart';

class BookCar {
  final BookingsRepository _repository;
  const BookCar(this._repository);

  Future<List<Booking>> call(Car car, {int? offerPrice}) {
    if (offerPrice != null) {
      final error = OfferRules.validate(offer: offerPrice, carPrice: car.price);
      if (error != null) throw ValidationFailure(error); // قاعدة الدومين
    }
    return _repository.book(car, offerPrice: offerPrice);
  }
}
