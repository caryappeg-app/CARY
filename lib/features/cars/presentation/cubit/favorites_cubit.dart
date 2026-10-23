// Presentation: منطق المفضلات
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/car.dart';
import '../../domain/usecases/clear_favorites.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/toggle_favorite.dart';

class FavoritesState {
  final List<Car> cars;
  const FavoritesState([this.cars = const []]);

  Set<String> get ids => cars.map((c) => c.id).toSet();
  bool isFavorite(String id) => cars.any((c) => c.id == id);
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavorites _getFavorites;
  final ToggleFavorite _toggleFavorite;
  final ClearFavorites _clearFavorites;

  FavoritesCubit({
    required GetFavorites getFavorites,
    required ToggleFavorite toggleFavorite,
    required ClearFavorites clearFavorites,
  })  : _getFavorites = getFavorites,
        _toggleFavorite = toggleFavorite,
        _clearFavorites = clearFavorites,
        super(const FavoritesState());

  Future<void> load() async {
    final cars = await _getFavorites();
    if (!isClosed) emit(FavoritesState(cars));
  }

  Future<void> toggle(Car car) async {
    final cars = await _toggleFavorite(car);
    if (!isClosed) emit(FavoritesState(cars));
  }

  Future<void> clear() async {
    await _clearFavorites();
    if (!isClosed) emit(const FavoritesState());
  }
}
