// Domain: قواعد صلاحية السيارة (بتمنع الحالات الغلط قبل ما توصل للـ UI)
import 'car.dart';

class CarRules {
  CarRules._();

  static const int minYear = 1950;
  static const int maxPrice = 100000000;
  static const int maxKm = 2000000;

  static bool isValid(Car c) {
    final maxYear = DateTime.now().year + 1;
    return c.id.isNotEmpty &&
        c.brand.isNotEmpty &&
        c.model.isNotEmpty &&
        c.year >= minYear &&
        c.year <= maxYear &&
        c.price >= 0 &&
        c.price <= maxPrice &&
        c.km >= 0 &&
        c.km <= maxKm;
  }
}
