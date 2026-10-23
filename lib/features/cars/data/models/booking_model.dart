// Data: موديل الحجز — JSON <-> Entity
import '../../domain/entities/booking.dart';
import 'car_model.dart';

class BookingModel {
  final CarModel car;
  final int? offerPrice;
  const BookingModel({required this.car, this.offerPrice});

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        car: CarModel.fromJson(Map<String, dynamic>.from(json['car'] as Map)),
        offerPrice: (json['offer_price'] as num?)?.toInt(),
      );

  factory BookingModel.fromEntity(Booking b) => BookingModel(
        car: CarModel.fromEntity(b.car),
        offerPrice: b.offerPrice,
      );

  Map<String, dynamic> toJson() => {
        'car': car.toJson(),
        'offer_price': offerPrice,
      };

  Booking toEntity() => Booking(car: car.toEntity(), offerPrice: offerPrice);
}
