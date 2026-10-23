import 'dart:convert';

import 'package:flutter/services.dart';

/// مكان ملف الجايسون جوه المشروع (لازم يكون متضاف في pubspec.yaml)
const kBrandsJsonAsset = 'assets/car_brands.json';

class CarBrand {
  final int id;
  final String nameAr;
  final String nameEn;
  final String logoUrl;
  final String countryAr;
  final String countryEn;

  const CarBrand({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.logoUrl,
    this.countryAr = '',
    this.countryEn = '',
  });

  factory CarBrand.fromJson(Map<String, dynamic> j) => CarBrand(
    id: (j['id'] as num?)?.toInt() ?? 0,
    nameAr: (j['name_ar'] ?? '').toString().trim(),
    nameEn: (j['name_en'] ?? '').toString().trim(),
    logoUrl: (j['logo_url'] ?? '').toString().trim(),
    countryAr: (j['country_ar'] ?? '').toString().trim(),
    countryEn: (j['country'] ?? '').toString().trim(),
  );

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim();

  /// هل اسم الماركة اللي على السيارة (Car.brand) هو نفس الماركة دي؟
  bool matches(String carBrand) {
    final c = _norm(carBrand);
    if (c.isEmpty) return false;
    final ar = _norm(nameAr);
    final en = _norm(nameEn);
    return c == ar ||
        c == en ||
        (ar.isNotEmpty && (ar.contains(c) || c.contains(ar))) ||
        (en.isNotEmpty && (en.contains(c) || c.contains(en)));
  }

  @override
  bool operator ==(Object other) => other is CarBrand && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static Future<List<CarBrand>>? _cache;

  /// تحميل كل الماركات من ملف الجايسون (بيتحمل مرة واحدة وبيتخزن)
  static Future<List<CarBrand>> loadAll() => _cache ??= _load();

  /// يدوّر على ماركة السيارة (Car.brand) ويرجّع بياناتها (اللوجو وغيره)
  static Future<CarBrand?> findFor(String carBrand) async {
    final all = await loadAll();
    final c = _norm(carBrand);
    if (c.isEmpty) return null;
    // الأول تطابق تام، وبعدين تطابق جزئي
    for (final b in all) {
      if (_norm(b.nameAr) == c || _norm(b.nameEn) == c) return b;
    }
    for (final b in all) {
      if (b.matches(carBrand)) return b;
    }
    return null;
  }

  static Future<List<CarBrand>> _load() async {
    final raw = await rootBundle.loadString(kBrandsJsonAsset);
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((m) => CarBrand.fromJson(Map<String, dynamic>.from(m)))
        .where((b) => b.nameAr.isNotEmpty || b.nameEn.isNotEmpty)
        .toList();
  }
}