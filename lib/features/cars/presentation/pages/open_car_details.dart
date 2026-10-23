// Presentation: فتح شاشة "عرض التفاصيل وحجز السيارة" (نقطة واحدة لكل التابات)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../screens/ads_store.dart';
import '../../../../screens/bookings_store.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../domain/entities/car.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/favorites_cubit.dart';
import 'car_details_screen.dart';

/// [onBooked] بتتنادى بعد تأكيد الحجز (الشاشة الرئيسية بتنقلك لتاب حجوزاتي)
void openCarDetails(
  BuildContext context,
  Car initialCar, {
  required VoidCallback onBooked,
}) {
  // بنمسك الـ Cubits قبل الـ push لأن الشاشة الجديدة route مستقل
  final favorites = context.read<FavoritesCubit>();
  final bookings = context.read<BookingsCubit>();
  final buyer = context.read<AccountCubit>().state.profile;

  // أحدث بيانات للسيارة (لو الإعلان اتعدّل بعد ما اتحفظت)
  final car = AdsStore.instance.freshCar(initialCar);
  // صاحب الإعلان ما ينفعش يحجز سيارته بنفسه
  final myEmail = (buyer?.email ?? '').trim().toLowerCase();
  final isOwnCar = myEmail.isNotEmpty &&
      AdsStore.instance.ownerEmailForCar(car.id) == myEmail;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CarDetailsScreen(
        car: car,
        bookingBlockedMessage:
            isOwnCar ? 'ده إعلانك — مينفعش تحجز سيارتك بنفسك' : null,
        isFavorite: favorites.state.isFavorite(car.id),
        onFavorite: () => favorites.toggle(car),
        onBook: (c, offerPrice) {
          bookings.book(c, offerPrice: offerPrice);
          // يظهر في "إدارة الحجوزات" عند الأدمن والمالك
          BookingsAdminStore.instance
              .record(car: c, offerPrice: offerPrice, buyer: buyer);
          onBooked();
        },
      ),
    ),
  );
}
