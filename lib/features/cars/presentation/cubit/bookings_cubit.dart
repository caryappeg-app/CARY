// Presentation: منطق الحجوزات
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking.dart';
import '../../domain/entities/car.dart';
import '../../domain/usecases/book_car.dart';
import '../../domain/usecases/clear_bookings.dart';
import '../../domain/usecases/get_bookings.dart';
import '../../domain/usecases/remove_booking.dart';

class BookingsState {
  final List<Booking> items;
  const BookingsState([this.items = const []]);

  /// السيارات المحجوزة (للعدّاد والقايمة)
  List<Car> get cars => items.map((b) => b.car).toList();

  /// السعر المقترح لسيارة معيّنة (null لو مفيش عرض)
  int? offerFor(String carId) {
    for (final b in items) {
      if (b.car.id == carId) return b.offerPrice;
    }
    return null;
  }
}

class BookingsCubit extends Cubit<BookingsState> {
  final GetBookings _getBookings;
  final BookCar _bookCar;
  final ClearBookings _clearBookings;
  final RemoveBooking _removeBooking;

  BookingsCubit({
    required GetBookings getBookings,
    required BookCar bookCar,
    required ClearBookings clearBookings,
    required RemoveBooking removeBooking,
  })  : _getBookings = getBookings,
        _bookCar = bookCar,
        _clearBookings = clearBookings,
        _removeBooking = removeBooking,
        super(const BookingsState());

  Future<void> load() async {
    final items = await _getBookings();
    if (!isClosed) emit(BookingsState(items));
  }

  Future<void> book(Car car, {int? offerPrice}) async {
    try {
      final items = await _bookCar(car, offerPrice: offerPrice);
      if (!isClosed) emit(BookingsState(items));
    } catch (_) {
      // العرض بيتراجع في الشاشة قبل الإرسال؛ هنا بس حماية إضافية
    }
  }

  /// حذف حجز سيارة واحدة (بيتشال كمان من "إدارة الحجوزات" عند الأدمن والمالك)
  Future<void> remove(String carId) async {
    final items = await _removeBooking(carId);
    if (!isClosed) emit(BookingsState(items));
  }

  Future<void> clear() async {
    await _clearBookings();
    if (!isClosed) emit(const BookingsState());
  }
}
