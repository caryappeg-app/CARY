// Data: إعلانات السيارات على Supabase.
// - القراءة: RPC `list_ads` (المالك/الأدمن = الكل، المستخدم = إعلاناته بس).
// - إضافة إعلان: رفع الصور على Supabase Storage (bucket: car-images) ثم insert في جدول cars.
//   الداتابيز بتجبر الإعلان الجديد يبقى "قيد المراجعة" وبتحدد صاحبه تلقائيًا.
// - القبول / الرفض / الحذف / تم البيع / التعديل: RPCs بتتحقق من الصلاحية على السيرفر.
import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart' show XFile;
import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../screens/my_ad.dart';

class AdsSnapshot {
  final List<MyAd> active;
  final List<MyAd> deleted;
  const AdsSnapshot(this.active, this.deleted);
}

class AdsRemote {
  static const int _maxImageBytes = 5 * 1024 * 1024; // التطبيق بيضغط الصور قبل الرفع (غالبًا أقل من 1MB)

  final ApiClient _client;
  AdsRemote(this._client);

  Map<String, dynamic>? _me;

  /// بيتنادى عند تسجيل الخروج (الحساب الحالي بيتغيّر)
  void reset() => _me = null;

  Future<Map<String, dynamic>> _profile() async {
    final cached = _me;
    if (cached != null) return cached;
    final json = await _client.post('/rest/v1/rpc/my_profile', body: const {});
    if (json is! Map) throw const ServerFailure();
    return _me = Map<String, dynamic>.from(json);
  }

  // ---------------------------------------------------------------- قراءة
  /// "نسخة" الإعلانات على السيرفر (نص صغير جدًا): لو ما اتغيّرتش مفيش داعي نسحب القايمة كاملة
  Future<String> version() async {
    final v = await _client.post('/rest/v1/rpc/ads_version', body: const {});
    return v is String ? v : '';
  }

  Future<AdsSnapshot> fetchAll() async {
    final json = await _client.post('/rest/v1/rpc/list_ads', body: const {});
    final active = <MyAd>[];
    final deleted = <MyAd>[];
    if (json is List) {
      for (final m in json.whereType<Map>()) {
        final row = Map<String, dynamic>.from(m);
        (row['deleted_at'] != null ? deleted : active).add(_fromRow(row));
      }
    }
    return AdsSnapshot(active, deleted);
  }

  // ---------------------------------------------------------------- كتابة
  Future<MyAd> create(MyAd ad) async {
    final me = await _profile();
    final urls = await _resolveImages(ad.allImages, me['id'].toString());
    final res = await _client.post(
      '/rest/v1/cars',
      body: {..._columns(ad), 'images': urls},
      headers: {'Prefer': 'return=representation'},
    );
    final row = res is List && res.isNotEmpty ? res.first : res;
    if (row is! Map) throw const ServerFailure();
    return _fromRow({
      ...Map<String, dynamic>.from(row),
      'owner_name': me['full_name'],
      'owner_phone': me['phone'],
      'owner_email': me['email'],
    });
  }

  /// تعديل إعلان (صورة جديدة من الجهاز بتترفع، واللي عليها رابط بتفضل زي ما هي)
  Future<MyAd> update(MyAd ad) async {
    final me = await _profile();
    final urls = await _resolveImages(ad.allImages, me['id'].toString());
    await _client.post('/rest/v1/rpc/update_ad', body: {
      'p_car_id': ad.carId,
      'p_data': {..._columns(ad), 'images': urls},
    });
    return ad.copyWith(images: urls);
  }

  Future<void> approve(String carId) => _rpc(
      'moderate_ad', {'p_car_id': carId, 'p_status': 'approved'});

  Future<void> reject(String carId, String reason) => _rpc('moderate_ad',
      {'p_car_id': carId, 'p_status': 'rejected', 'p_reason': reason});

  Future<void> delete(String carId, String reason) =>
      _rpc('delete_ad', {'p_car_id': carId, 'p_reason': reason});

  Future<void> purgePermanently(String carId) async {
    try {
      await _client.delete('/rest/v1/cars?id=eq.$carId');
    } catch (_) {
      try {
        await _rpc('purge_ad', {'p_car_id': carId});
      } catch (e) {
        debugPrint('purgePermanently error: $e');
      }
    }
  }

  Future<void> markSold(String carId) =>
      _rpc('mark_ad_sold', {'p_car_id': carId});

  Future<void> _rpc(String name, Map<String, dynamic> body) async {
    await _client.post('/rest/v1/rpc/$name', body: body);
  }

  // ---------------------------------------------------------------- الصور
  Future<List<String>> _resolveImages(List<String> paths, String uid) async {
    // الصور بتترفع بالتوازي (مع الحفاظ على الترتيب؛ الأولى = الرئيسية)
    final slots = <String>[]; // رابط جاهز، أو مسار محلي محتاج رفع
    for (final raw in paths) {
      final p = raw.trim();
      if (p.isNotEmpty) slots.add(p);
    }
    bool isRemote(String p) => p.startsWith('https://') || p.startsWith('assets/');
    final toUpload = slots.where((p) => !isRemote(p)).toList();
    final uploaded =
        toUpload.isEmpty ? const <String>[] : await _uploadAll(toUpload, uid);
    var next = 0;
    final out = [for (final p in slots) isRemote(p) ? p : uploaded[next++]];
    if (out.isEmpty) throw const ValidationFailure('ضيف صورة واحدة على الأقل');
    return out;
  }

  /// رفع الصور الجديدة: R2 عن طريق الـ Worker، ولو فشل (الشبكة / إعداد ناقص) Supabase Storage
  Future<List<String>> _uploadAll(List<String> localPaths, String uid) async {
    // قراءة وفحص كل الصور الأول (حجم/نوع): أي مشكلة فيها بتظهر للمستخدم فورًا
    final images = await Future.wait(localPaths.map(_readImage));
    if (AppConfig.adsWorkerUrl.isNotEmpty) {
      try {
        return await _uploadViaWorker(images);
      } catch (e) {
        debugPrint('R2 worker upload failed (${e.runtimeType}) -> Supabase Storage');
      }
    }
    return Future.wait(images.map((b) => _upload(b, uid)));
  }

  /// R2 عن طريق الـ Cloudflare Worker (طلب واحد لكل الصور، والترتيب محفوظ)
  Future<List<String>> _uploadViaWorker(List<Uint8List> images) async {
    final form = FormData();
    for (final bytes in images) {
      final kind = _sniff(bytes)!;
      form.files.add(MapEntry(
        'images',
        MultipartFile.fromBytes(bytes, filename: 'photo.${kind.ext}'),
      ));
    }
    final base = AppConfig.adsWorkerUrl.replaceAll(RegExp(r'/+$'), '');
    final res = await _client.post('$base/images', body: form);
    final list = res is Map ? res['images'] : null;
    if (list is! List || list.length != images.length) {
      throw const ServerFailure();
    }
    return list.map((e) => e.toString()).toList();
  }

  Future<Uint8List> _readImage(String localPath) async {
    final Uint8List bytes;
    try {
      bytes = await XFile(localPath).readAsBytes();
    } catch (_) {
      throw const ValidationFailure('تعذّر قراءة إحدى الصور');
    }
    if (bytes.isEmpty || bytes.length > _maxImageBytes) {
      throw const ValidationFailure('حجم كل صورة لازم يكون أقل من 5MB');
    }
    if (_sniff(bytes) == null) {
      throw const ValidationFailure('الصور لازم تكون JPG أو PNG أو WEBP');
    }
    return bytes;
  }

  /// بديل لو الـ Worker مش متظبط: Supabase Storage
  Future<String> _upload(Uint8List bytes, String uid) async {
    final kind = _sniff(bytes)!;
    final rnd = Random.secure();
    final tag = List.generate(6, (_) => rnd.nextInt(16).toRadixString(16)).join();
    final objectPath =
        '$uid/${DateTime.now().microsecondsSinceEpoch}_$tag.${kind.ext}';
    await _client.post(
      '/storage/v1/object/car-images/$objectPath',
      body: bytes,
      headers: {
        'Content-Type': kind.mime,
        // الصورة عمرها ما بتتغيّر (اسمها فريد) => كاش لمدة سنة
        'Cache-Control': 'max-age=31536000',
      },
    );
    return '${AppConfig.apiBaseUrl}/storage/v1/object/public/car-images/$objectPath';
  }

  static _ImageKind? _sniff(Uint8List b) {
    if (b.length < 12) return null;
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return const _ImageKind('jpg', 'image/jpeg');
    }
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return const _ImageKind('png', 'image/png');
    }
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return const _ImageKind('webp', 'image/webp');
    }
    return null;
  }

  // ---------------------------------------------------------------- التحويل
  /// MyAd -> أعمدة جدول cars
  static Map<String, dynamic> _columns(MyAd ad) {
    String d(String k) => (ad.details[k] ?? '').trim();
    final drive = d('الدفع').isNotEmpty ? d('الدفع') : d('نوع المحرك');
    return {
      'brand': ad.brandName,
      'model': ad.model,
      'year': ad.year,
      'km': ad.km,
      'price': ad.price,
      'transmission':
          ad.transmission.isNotEmpty ? ad.transmission : d('ناقل الحركة'),
      'location': ad.location,
      'body_type': d('شكل السيارة'),
      'drive': drive,
      'engine': d('سعة المحرك'),
      'horsepower': d('القوة'),
      'license': d('الرخصة'),
      'exterior_color': d('اللون'),
      'interior_condition': d('الداخلية'),
      'exterior_condition': d('الخارجية'),
      'paint_status': d('الدهان'),
      'gearbox_condition': d('الجير'),
      'suspension_condition': d('المساعدين'),
      'engine_problems': d('مشاكل المحرك'),
      'accident_status': d('الحوادث'),
      'condition': d('الحالة'),
      'description': d('الوصف'),
      'negotiable': d('قابل للتفاوض') == 'نعم',
    };
  }

  static String _s(Object? v) => (v ?? '').toString();
  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;
  static DateTime? _dt(Object? v) =>
      v == null ? null : DateTime.tryParse(_s(v))?.toLocal();

  /// صف من جدول cars (+ بيانات الصاحب) -> MyAd
  static MyAd _fromRow(Map<String, dynamic> r) {
    final isCatalog = r['is_catalog'] == true;
    final id = _s(r['id']);
    final images = (r['images'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final status = switch (_s(r['status'])) {
      'approved' => MyAdStatus.approved,
      'rejected' => MyAdStatus.rejected,
      'sold' => MyAdStatus.sold,
      _ => MyAdStatus.pending,
    };
    final drive = _s(r['drive']);
    final details = <String, String>{
      'نوع المحرك': drive,
      'الدفع': drive,
      'ناقل الحركة': _s(r['transmission']),
      'الحالة': _s(r['condition']),
      'اللون': _s(r['exterior_color']),
      'سعة المحرك': _s(r['engine']),
      'القوة': _s(r['horsepower']),
      'الرخصة': _s(r['license']),
      'وحدة المرور': _s(r['location']),
      'الداخلية': _s(r['interior_condition']),
      'الخارجية': _s(r['exterior_condition']),
      'الدهان': _s(r['paint_status']),
      'الجير': _s(r['gearbox_condition']),
      'المساعدين': _s(r['suspension_condition']),
      'مشاكل المحرك': _s(r['engine_problems']),
      'الحوادث': _s(r['accident_status']),
      'شكل السيارة': _s(r['body_type']),
      'قابل للتفاوض': r['negotiable'] == true ? 'نعم' : 'لا',
      if (_s(r['description']).isNotEmpty) 'الوصف': _s(r['description']),
    };
    final rejection = _s(r['rejection_reason']);
    return MyAd(
      id: isCatalog ? 'catalog:$id' : id,
      brandName: _s(r['brand']),
      brandLogoUrl: '',
      model: _s(r['model']),
      year: _i(r['year']),
      km: _i(r['km']),
      transmission: _s(r['transmission']),
      location: _s(r['location']),
      price: _i(r['price']),
      imagePath: images.isNotEmpty ? images.first : '',
      images: images,
      createdAt: _dt(r['created_at']) ?? DateTime.now(),
      approvedAt: _dt(r['approved_at']),
      status: status,
      ownerName: isCatalog ? 'CARY - إعلان الصفحة الرئيسية' : _s(r['owner_name']),
      ownerPhone: isCatalog ? '' : _s(r['owner_phone']),
      ownerEmail: isCatalog ? '' : _s(r['owner_email']),
      details: details,
      rejectionReason: rejection.isEmpty ? null : rejection,
      deletionReason: r['deleted_at'] != null ? _s(r['deletion_reason']) : null,
      isCatalog: isCatalog,
    );
  }
}

class _ImageKind {
  final String ext;
  final String mime;
  const _ImageKind(this.ext, this.mime);
}
