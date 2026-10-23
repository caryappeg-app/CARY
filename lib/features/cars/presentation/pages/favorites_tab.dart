// Presentation: تاب المفضلات
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../screens/ads_store.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/car_card.dart';
import '../widgets/saved_cars_tab.dart';
import 'open_car_details.dart';

class FavoritesTab extends StatelessWidget {
  final VoidCallback onBooked;
  const FavoritesTab({super.key, required this.onBooked});

  @override
  Widget build(BuildContext context) {
    // بنسمع لمخزن الإعلانات عشان علامة "غير متاحة" تتحدّث فورًا
    return ListenableBuilder(
      listenable: AdsStore.instance,
      builder: (context, _) => BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        final cubit = context.read<FavoritesCubit>();
        return SavedCarsTab(
          cars: state.cars,
          searchHint: 'ابحث في المفضلات...',
          emptyTitle: 'مفيش سيارات في المفضلة',
          emptySubtitle: 'اضغط على القلب في أي سيارة عشان تضيفها هنا',
          emptyIcon: Icons.favorite_border,
          clearTitle: 'مسح المفضلات',
          clearMessage: 'هتتمسح كل السيارات من المفضلات. متأكد؟',
          onClear: cubit.clear,
          cardBuilder: (context, car) => CarCard(
            car: car,
            isFavorite: true,
            available: AdsStore.instance.isCarAvailable(car.id),
            onFavorite: () => cubit.toggle(car),
            onDetails: () => openCarDetails(context, car, onBooked: onBooked),
          ),
        );
      },
    ),
    );
  }
}
