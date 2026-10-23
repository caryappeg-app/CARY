// Presentation: تاب حجوزاتي
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../screens/ads_store.dart';
import '../../../../screens/bookings_store.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/car_card.dart';
import '../widgets/saved_cars_tab.dart';
import 'open_car_details.dart';

class BookingsTab extends StatelessWidget {
  final VoidCallback onBooked;
  const BookingsTab({super.key, required this.onBooked});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesCubit>();

    return ListenableBuilder(
      listenable: AdsStore.instance,
      builder: (context, _) => BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        final cubit = context.read<BookingsCubit>();
        final buyerEmail =
            context.read<AccountCubit>().state.profile?.email ?? '';
        return SavedCarsTab(
          cars: state.cars,
          searchHint: 'ابحث في حجوزاتي...',
          emptyTitle: 'مفيش حجوزات لسه',
          emptySubtitle: 'السيارات اللي بتحجزها بتظهر هنا',
          emptyIcon: Icons.calendar_month_outlined,
          clearTitle: 'مسح الحجوزات',
          clearMessage: 'هيتم مسح كل الحجوزات. متأكد؟',
          onClear: () {
            // مسح الكل: نشيل نفس الحجوزات من "إدارة الحجوزات" كمان
            for (final c in state.cars) {
              BookingsAdminStore.instance.removeForBuyer(c.id, buyerEmail);
            }
            cubit.clear();
          },
          cardBuilder: (context, car) => CarCard(
            car: car,
            offerPrice: state.offerFor(car.id), // السعر اللي المستخدم كتبه
            available: AdsStore.instance.isCarAvailable(car.id),
            isFavorite: favorites.state.isFavorite(car.id),
            onFavorite: () => favorites.toggle(car),
            onDetails: () => openCarDetails(context, car, onBooked: onBooked),
            onDelete: () {
              // حذف من حجوزاتي + من إدارة الحجوزات تلقائي
              BookingsAdminStore.instance.removeForBuyer(car.id, buyerEmail);
              cubit.remove(car.id);
            },
          ),
        );
      },
    ),
    );
  }
}
