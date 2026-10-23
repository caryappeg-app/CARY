// Domain: معايير البحث والفلترة (قيمة ثابتة Immutable)
import 'car.dart';
import 'car_sort.dart';

class CarFilter {
  final String query; // بحث بالماركة / الموديل / الفئة
  final String model;

  /// أسماء الماركة المختارة (عربي + إنجليزي) — فاضية = كل الماركات
  final List<String> brandNames;
  final int? yearFrom;
  final int? yearTo;
  final int? priceFrom;
  final int? priceTo;
  final CarSort sort;

  const CarFilter({
    this.query = '',
    this.model = '',
    this.brandNames = const [],
    this.yearFrom,
    this.yearTo,
    this.priceFrom,
    this.priceTo,
    this.sort = CarSort.defaultOrder,
  });

  static const _unset = Object();

  /// القيم اللي ممكن تتمسح (null) بتتبعت صراحةً، وغير كده بتفضل زي ما هي.
  CarFilter copyWith({
    String? query,
    String? model,
    List<String>? brandNames,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    Object? priceFrom = _unset,
    Object? priceTo = _unset,
    CarSort? sort,
  }) {
    return CarFilter(
      query: query ?? this.query,
      model: model ?? this.model,
      brandNames: brandNames ?? this.brandNames,
      yearFrom: identical(yearFrom, _unset) ? this.yearFrom : yearFrom as int?,
      yearTo: identical(yearTo, _unset) ? this.yearTo : yearTo as int?,
      priceFrom:
          identical(priceFrom, _unset) ? this.priceFrom : priceFrom as int?,
      priceTo: identical(priceTo, _unset) ? this.priceTo : priceTo as int?,
      sort: sort ?? this.sort,
    );
  }

  /// مفتاح ثابت للفلتر (بيستخدم في الكاش)
  String get cacheKey => [
        query.trim().toLowerCase(),
        model.trim().toLowerCase(),
        brandNames.join(','),
        yearFrom,
        yearTo,
        priceFrom,
        priceTo,
        sort.name,
      ].join('|');

  /// هل السيارة دي مطابقة للفلتر (الترتيب بيتعمل منفصل في [sorted])
  bool matches(Car c) {
    final q = query.trim().toLowerCase();
    final m = model.trim().toLowerCase();
    if (q.isNotEmpty &&
        !'${c.brand} ${c.model} ${c.bodyType}'.toLowerCase().contains(q)) {
      return false;
    }
    if (brandNames.isNotEmpty && !_brandMatches(c.brand)) return false;
    if (m.isNotEmpty && !c.model.toLowerCase().contains(m)) return false;
    if (yearFrom != null && c.year < yearFrom!) return false;
    if (yearTo != null && c.year > yearTo!) return false;
    if (priceFrom != null && c.price < priceFrom!) return false;
    if (priceTo != null && c.price > priceTo!) return false;
    return true;
  }

  List<Car> sorted(List<Car> list) {
    final out = List<Car>.of(list);
    switch (sort) {
      case CarSort.defaultOrder:
        break;
      case CarSort.priceAsc:
        out.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CarSort.priceDesc:
        out.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CarSort.yearDesc:
        out.sort((a, b) => b.year.compareTo(a.year));
        break;
      case CarSort.kmAsc:
        out.sort((a, b) => a.km.compareTo(b.km));
        break;
    }
    return out;
  }

  // ---- مطابقة اسم الماركة (نفس منطق CarBrand.matches بالظبط)
  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim();

  bool _brandMatches(String carBrand) {
    final c = _norm(carBrand);
    if (c.isEmpty) return false;
    for (final name in brandNames) {
      final n = _norm(name);
      if (n.isEmpty) continue;
      if (c == n || n.contains(c) || c.contains(n)) return true;
    }
    return false;
  }
}
