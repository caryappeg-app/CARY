// Core: عقد التخزين الآمن (التوكنز والبيانات الحساسة) — مش SharedPreferences العادية.
abstract class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

/// نسخة في الذاكرة للتجارب والـ tests فقط (مبتتخزنش على الجهاز)
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}
