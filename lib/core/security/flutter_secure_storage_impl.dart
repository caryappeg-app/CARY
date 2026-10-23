// Core: تخزين مشفّر فعلي (Android Keystore / iOS Keychain) عن طريق flutter_secure_storage.
// الملف ده الوحيد اللي بيعتمد على الحزمة — مش مستورد من أي مكان لحد ما تربط الـ Auth.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

class FlutterSecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _s;

  const FlutterSecureStorageImpl([
    this._s = const FlutterSecureStorage(

      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  ]);

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);

  @override
  Future<void> clear() => _s.deleteAll();
}
