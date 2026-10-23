// Data: كاش محلي لصفحات السيارات (Offline-First).
// النسخة الحالية في الذاكرة؛ ممكن تتبدل بـ Hive / SQLite / SharedPreferences من غير ما أي طبقة تانية تتغير.
import '../models/car_model.dart';

abstract class CarLocalDataSource {
  Future<CarsPageModel?> getCachedPage(String key);
  Future<void> cachePage(String key, CarsPageModel page);
  Future<Map<String, int>?> getCachedBrandCounts();
  Future<void> cacheBrandCounts(Map<String, int> counts);
  Future<void> clear();
}

class InMemoryCarLocalDataSource implements CarLocalDataSource {
  final Duration ttl;
  final int maxEntries;

  InMemoryCarLocalDataSource({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 40,
  });

  final Map<String, _Entry> _pages = {};
  Map<String, int>? _brandCounts;

  @override
  Future<CarsPageModel?> getCachedPage(String key) async {
    final e = _pages[key];
    if (e == null) return null;
    if (DateTime.now().difference(e.savedAt) > ttl) {
      _pages.remove(key);
      return null;
    }
    return e.page;
  }

  @override
  Future<void> cachePage(String key, CarsPageModel page) async {
    if (_pages.length >= maxEntries) _pages.remove(_pages.keys.first);
    _pages[key] = _Entry(page, DateTime.now());
  }

  @override
  Future<Map<String, int>?> getCachedBrandCounts() async => _brandCounts;

  @override
  Future<void> cacheBrandCounts(Map<String, int> counts) async =>
      _brandCounts = counts;

  @override
  Future<void> clear() async {
    _pages.clear();
    _brandCounts = null;
  }
}

class _Entry {
  final CarsPageModel page;
  final DateTime savedAt;
  _Entry(this.page, this.savedAt);
}
