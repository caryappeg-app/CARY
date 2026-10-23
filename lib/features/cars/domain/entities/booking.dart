// Domain: حجز سيارة (السيارة + السعر اللي قدّمه المستخدم لو فيه عرض)
import 'car.dart';

class Booking {
  final Car car;

  /// السعر المقترح من المستخدم (null = حجز عادي بدون عرض سعر)
  final int? offerPrice;

  const Booking({required this.car, this.offerPrice});
}
