// Data: تخزين محلي للحجوزات. النسخة الحالية في الذاكرة؛
// استبدلها بـ SharedPreferences / Hive / API من غير ما أي طبقة تانية تتغير.
import '../models/booking_model.dart';

abstract class BookingsLocalDataSource {
  Future<List<BookingModel>> read();
  Future<void> write(List<BookingModel> bookings);
}

class InMemoryBookingsLocalDataSource implements BookingsLocalDataSource {
  List<BookingModel> _items = const [];

  @override
  Future<List<BookingModel>> read() async => List<BookingModel>.of(_items);

  @override
  Future<void> write(List<BookingModel> bookings) async =>
      _items = List<BookingModel>.of(bookings);
}
