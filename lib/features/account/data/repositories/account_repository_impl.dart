// Data: تطبيق AccountRepository فوق التخزين الآمن (SecureStorage)
import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/secure_storage.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_mock_data.dart';

class AccountRepositoryImpl implements AccountRepository {
  static const _kProfile = 'account.profile';
  static const _kRegistered = 'account.registered';

  final SecureStorage _storage;
  const AccountRepositoryImpl(this._storage);

  Future<UserProfile?> _read(String key) async {
    final raw = await _storage.read(key);
    if (raw == null || raw.isEmpty) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return UserProfile(
      fullName: (m['fullName'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      role: UserRoleX.fromKey((m['role'] ?? '').toString()),
    );
  }

  Future<void> _write(String key, UserProfile p) => _storage.write(
    key,
    jsonEncode({
      'fullName': p.fullName,
      'email': p.email,
      'phone': p.phone,
      'role': p.role.key,
    }),
  );

  @override
  Future<UserProfile?> getProfile() => _read(_kProfile);

  @override
  Future<void> saveRegistration(UserProfile profile) =>
      _write(_kRegistered, profile);

  @override
  Future<void> signIn(String identifier) async {
    final id = identifier.trim();

    bool sameAccount(UserProfile p) =>
        (p.phone.isNotEmpty && p.phone == id) ||
            (p.email.isNotEmpty && p.email.toLowerCase() == id.toLowerCase());

    // مع الـ Backend: الحسابات التجريبية متتطبّقش، والبروفايل الحقيقي (الاسم + الصلاحية)
    // بيتطبّق بعد كده من السيرفر في شاشة الدخول (userAdminRepository.findByIdentifier).
    if (AppConfig.useBackend) {
      final isEmail = id.contains('@');
      await _write(
        _kProfile,
        UserProfile(email: isEmail ? id : '', phone: isEmail ? '' : id),
      );
      return;
    }

    // 1) الحسابات الثابتة (مالك / أدمن / مستخدم): لو الدخول بالإيميل أو
    //    الرقم بتاع أي واحد فيهم بتظهر بياناته وحالته تلقائياً
    for (final account in kMockAccounts) {
      if (sameAccount(account)) {
        await _write(_kProfile, account);
        return;
      }
    }

    // 2) حساب اتسجّل من شاشة إنشاء حساب بنفس الهاتف أو الإيميل
    final registered = await _read(_kRegistered);
    if (registered != null && sameAccount(registered)) {
      await _write(_kProfile, registered);
      return;
    }

    // 3) أي دخول تاني: بنحفظ اللي كتبه بس (هاتف أو إيميل)، والباقي "غير متوفر"
    final isEmail = id.contains('@');
    await _write(
      _kProfile,
      UserProfile(email: isEmail ? id : '', phone: isEmail ? '' : id),
    );
  }

  @override
  Future<void> applyProfile(UserProfile profile) => _write(_kProfile, profile);

  @override
  Future<void> signOut() => _storage.delete(_kProfile);
}