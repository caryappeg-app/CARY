import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/di/injection.dart';
import '../core/error/failure.dart';
import '../features/ads/data/ads_remote.dart';
import '../features/cars/domain/entities/car.dart';
import '../features/notifications/domain/entities/app_notification.dart';
import 'my_ad.dart';

/// مخزن الإعلانات المشترك (In-Memory) بين صاحب الإعلان وشاشة إدارة الإعلانات
/// (أدمن / مالك). لما الـ API يتربط يتبدّل بـ Repository.
class AdsStore extends ChangeNotifier {
  AdsStore._();
  static final AdsStore instance = AdsStore._();

  final List<MyAd> _ads = [];

  // ------------------------------------------------------------------
  // الربط بالسيرفر (Supabase). في وضع التجربة كل ده بيتخطّى والمخزن يفضل في الذاكرة.
  // ------------------------------------------------------------------
  bool get _remote => AppConfig.useBackend;
  AdsRemote get _api => Injector.instance.adsRemote;

  /// رسالة خطأ آخر عملية مع السيرفر (الشاشة الرئيسية بتعرضها وبتصفّرها)
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  /// إعلانات لسه بتترفع (بتفضل ظاهرة محليًا لحد ما السيرفر يرد)
  final Set<String> _uploading = {};
  bool _loadedOnce = false;
  String? _serverVersion;
  String _approvedSig = '';

  static String _errText(Object e, String fallback) =>
      e is Failure ? e.message : fallback;

  /// تحميل الإعلانات من السيرفر: المالك/الأدمن يشوفوا الكل، والمستخدم إعلاناته بس
  Future<void> loadFromServer({bool force = false}) async {
    if (!_remote) return;
    try {
      // فحص خفيف (بايتات قليلة): القايمة كاملة بتتسحب بس لو فيه تغيير على السيرفر
      final version = await _api.version();
      if (!force && _loadedOnce && version == _serverVersion) return;
      final snap = await _api.fetchAll();
      _serverVersion = version;
      final inFlight = _ads.where((a) => _uploading.contains(a.id)).toList();
      _ads
        ..clear()
        ..addAll(inFlight)
        ..addAll(snap.active);
      _deleted
        ..clear()
        ..addAll(snap.deleted);
      // لو مجموعة الإعلانات المعروضة في الرئيسية اتغيّرت (قبول / بيع من جهاز تاني) نحدّث الرئيسية
      final sig = (_ads.where((a) => a.status == MyAdStatus.approved).map((a) => a.id).toList()
            ..sort())
          .join(',');
      if (_loadedOnce && sig != _approvedSig) _homeVersion++;
      _approvedSig = sig;
      _loadedOnce = true;
      notifyListeners();
    } catch (_) {
      // بنحافظ على آخر نسخة معروضة؛ المحاولة الجاية بعد شوية
    }
  }

  /// عند تسجيل الخروج: مسح بيانات المستخدم السابق (من غير إشعار للـ UI)
  void clearForLogout() {
    _ads.clear();
    _deleted.clear();
    _uploading.clear();
    _hiddenCatalogCarIds.clear();
    _loadedOnce = false;
    _serverVersion = null;
    _approvedSig = '';
    if (_remote) _api.reset();
  }

  /// تنفيذ عملية على السيرفر في الخلفية؛ لو فشلت بنبلّغ المستخدم ونرجّع الحالة الصحيحة
  void _push(Future<void> Function() call) {
    unawaited(() async {
      try {
        await call();
      } catch (e) {
        lastError.value = _errText(e, 'تعذّر تنفيذ العملية، اتأكد من الاتصال وجرّب تاني');
        await loadFromServer(force: true);
      }
    }());
  }

  Future<void> _submit(MyAd ad) async {
    _uploading.add(ad.id);
    try {
      final saved = await _api.create(ad);
      final i = _ads.indexWhere((a) => a.id == ad.id);
      if (i != -1) {
        _ads[i] = saved;
      } else {
        _ads.insert(0, saved);
      }
    } catch (e) {
      _ads.removeWhere((a) => a.id == ad.id);
      lastError.value = _errText(e, 'تعذّر رفع الإعلان، اتأكد من الاتصال وجرّب تاني');
    } finally {
      _uploading.remove(ad.id);
      notifyListeners();
    }
  }

  Future<void> _pushUpdate(MyAd ad) async {
    try {
      final saved = await _api.update(ad);
      final i = _ads.indexWhere((a) => a.id == ad.id);
      if (i != -1) {
        _ads[i] = saved;
        notifyListeners();
      }
    } catch (e) {
      lastError.value = _errText(e, 'تعذّر حفظ التعديل، جرّب تاني');
      await loadFromServer(force: true);
    }
  }

  /// الإعلانات اللي اتحذفت (مع سبب الحذف)
  final List<MyAd> _deleted = [];
  List<MyAd> get deleted => List.unmodifiable(_deleted);

  List<MyAd> get all => List.unmodifiable(_ads);

  List<MyAd> byStatus(MyAdStatus s) =>
      _ads.where((a) => a.status == s).toList();

  int count(MyAdStatus s) => _ads.where((a) => a.status == s).length;

  /// السيارة لسه متاحة؟ (مش اتباعت ولا اتحذفت ولا اترفضت) — لو مفيش إعلان
  /// معروف ليها بنعتبرها متاحة.
  bool isCarAvailable(String carId) {
    for (final a in _ads) {
      if (a.carId == carId) return a.status == MyAdStatus.approved;
    }
    if (_deleted.any((a) => a.carId == carId)) return false;
    return true;
  }

  /// أحدث نسخة من بيانات السيارة (لو الإعلان اتعدّل بعد ما اتحفظت في مفضلة/حجز)
  Car freshCar(Car c) {
    for (final a in _ads) {
      if (a.carId == c.id && a.status == MyAdStatus.approved && !a.isCatalog) {
        return a.toCar();
      }
    }
    return c;
  }

  /// إيميل صاحب إعلان السيارة (فاضي لو مش معروف)
  String ownerEmailForCar(String carId) {
    for (final a in _ads) {
      if (a.carId == carId) return a.ownerEmail.trim().toLowerCase();
    }
    return '';
  }

  /// إعلانات المستخدمين اللي اتقبلت (بتظهر في الصفحة الرئيسية)
  List<Car> get approvedUserCars => _ads
      .where((a) => !a.isCatalog && a.status == MyAdStatus.approved)
      .map((a) => a.toCar())
      .toList();

  /// رقم بيزيد كل ما حاجة تخص الصفحة الرئيسية تتغير (قبول / تعديل / حذف...)
  int _homeVersion = 0;
  int get homeVersion => _homeVersion;

  /// سيارات الكتالوج (التجريبية) اللي اتحذفت أو اتعدّلت — بتتشال من الرئيسية
  final Set<String> _hiddenCatalogCarIds = {};
  Set<String> get hiddenCatalogCarIds => Set.unmodifiable(_hiddenCatalogCarIds);

  bool _affectsHome(MyAd a) => a.isCatalog || a.status == MyAdStatus.approved;

  /// أي سيارة معروضة في الصفحة الرئيسية بتتصنّف تلقائيًا "تم المراجعة".
  /// آمنة للاستدعاء أكتر من مرة (مبتكرّرش السيارة، وبتحدّث بياناتها فقط).
  void syncCatalog(List<Car> cars) {
    if (_remote) return; // مع السيرفر: إعلانات الرئيسية بتيجي من list_ads
    var changed = false;
    final now = DateTime.now();
    for (final c in cars) {
      // سيارة جاية من إعلان مستخدم اتقبل: مش بنكرّرها كإعلان "كتالوج"
      if (_ads.any((a) => a.carId == c.id && !a.isCatalog)) continue;
      if (_hiddenCatalogCarIds.contains(c.id)) continue; // اتحذفت/اتعدّلت
      final id = 'catalog:${c.id}';
      final i = _ads.indexWhere((a) => a.id == id);
      if (i != -1) {
        // لو الأدمن/المالك غيّر حالتها (مثلاً تم بيعها) منرجّعهاش للمراجعة
        continue;
      }
      _ads.add(MyAd(
        id: id,
        brandName: c.brand,
        brandLogoUrl: '',
        model: c.model,
        year: c.year,
        km: c.km,
        transmission: c.transmission,
        location: c.trafficUnit,
        price: c.price,
        imagePath: c.image,
        createdAt: now,
        approvedAt: now, // إعلانات الرئيسية معتمدة تلقائيًا
        status: MyAdStatus.approved,
        ownerName: 'CARY - إعلان الصفحة الرئيسية',
        isCatalog: true,
        details: {
          'شكل السيارة': c.bodyType,
          'الدفع': c.drive,
          if (c.engine.isNotEmpty) 'سعة المحرك': c.engine,
          if (c.horsepower.isNotEmpty) 'القوة': c.horsepower,
          if (c.license.isNotEmpty) 'الرخصة': c.license,
          if (c.exteriorColor.isNotEmpty) 'اللون': c.exteriorColor,
          if (c.interiorCondition.isNotEmpty) 'الداخلية': c.interiorCondition,
          if (c.exteriorCondition.isNotEmpty) 'الخارجية': c.exteriorCondition,
          if (c.paintStatus.isNotEmpty) 'الدهان': c.paintStatus,
          if (c.gearboxCondition.isNotEmpty) 'الجير': c.gearboxCondition,
          if (c.suspensionCondition.isNotEmpty)
            'المساعدين': c.suspensionCondition,
          if (c.engineProblems.isNotEmpty) 'مشاكل المحرك': c.engineProblems,
          if (c.accidentStatus.isNotEmpty) 'الحوادث': c.accidentStatus,
          'قابل للتفاوض': c.negotiable ? 'نعم' : 'لا',
          if (c.description.isNotEmpty) 'الوصف': c.description,
        },
      ));
      changed = true;
    }
    if (changed) notifyListeners();
  }

  static String _titleOf(MyAd a) => '${a.brandName} ${a.model} ${a.year}'.trim();

  void add(MyAd ad) {
    _ads.insert(0, ad);
    if (_affectsHome(ad)) _homeVersion++;
    notifyListeners();
    if (_remote) {
      // السيرفر بيرفع الصور، بيحفظ الإعلان، وبيبعت إشعار للمالك والأدمن لوحده
      if (!ad.isCatalog) unawaited(_submit(ad));
      return;
    }
    // إشعار للأدمن والمالك: إعلان جديد من مستخدم قيد المراجعة
    if (!ad.isCatalog) {
      Injector.instance.notificationsRepository.publish(
        NotificationEvents.newAd(
          carTitle: _titleOf(ad),
          ownerName: ad.ownerName,
          ownerEmail: ad.ownerEmail,
        ),
      );
    }
  }

  void _update(String id, MyAd Function(MyAd) fn) {
    final i = _ads.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final old = _ads[i];
    final updated = fn(old);
    // إعلان كتالوج اتعدّل: نخفي الأصلي من الرئيسية ونعتبره إعلان عادي معروض
    if (old.isCatalog &&
        (!updated.isCatalog || updated.status == MyAdStatus.sold)) {
      _hiddenCatalogCarIds.add(old.id.replaceFirst('catalog:', ''));
    }
    _ads[i] = updated;
    if (_affectsHome(old) || _affectsHome(updated)) _homeVersion++;
    notifyListeners();
  }

  /// حذف إعلان مع سبب: بيتنقل لتاب "تم حذفها" (ولو كان معروض في الرئيسية بيتشال منها)
  void remove(String id, String reason) {
    final i = _ads.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final ad = _ads.removeAt(i);
    if (ad.isCatalog) {
      _hiddenCatalogCarIds.add(ad.id.replaceFirst('catalog:', ''));
    }
    _deleted.insert(0, ad.copyWith(deletionReason: reason.trim()));
    if (_affectsHome(ad)) _homeVersion++;
    notifyListeners();
    if (_remote) _push(() => _api.delete(ad.carId, reason.trim()));
  }

  /// حذف إعلان نهائياً من سلة المحذوفات (تم حذفها) ومن السيرفر
  Future<void> purgePermanently(String id) async {
    final i = _deleted.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final ad = _deleted.removeAt(i);
    notifyListeners();
    if (_remote) {
      _push(() => _api.purgePermanently(ad.carId));
    }
  }

  /// استبدال إعلان بنسخة معدّلة (نفس الـ id)
  void replace(MyAd ad) {
    _update(ad.id, (_) => ad);
    if (_remote) unawaited(_pushUpdate(ad));
  }

  /// قبول الإعلان (بيبقى معروض للعملاء)
  void approve(String id) {
    final old = _ads.where((a) => a.id == id).firstOrNull;
    _update(
        id,
        (a) => a.copyWith(
            status: MyAdStatus.approved, approvedAt: DateTime.now()));
    if (_remote) {
      // السيرفر بيبعت إشعار القبول لصاحب الإعلان لوحده
      if (old != null && !old.isCatalog) _push(() => _api.approve(old.carId));
      return;
    }
    // إشعار لصاحب الإعلان: من "قيد المراجعة" إلى "تم المراجعة"
    if (old != null && !old.isCatalog && old.status == MyAdStatus.pending) {
      Injector.instance.notificationsRepository.publish(
        NotificationEvents.adApproved(
          carTitle: _titleOf(old),
          ownerEmail: old.ownerEmail,
          ownerPhone: old.ownerPhone,
        ),
      );
    }
  }

  /// رفض الإعلان مع سبب يدوي
  void reject(String id, String reason) {
    final old = _ads.where((a) => a.id == id).firstOrNull;
    _update(
        id,
        (a) => a.copyWith(
            status: MyAdStatus.rejected, rejectionReason: reason.trim()));
    if (_remote) {
      if (old != null && !old.isCatalog) {
        _push(() => _api.reject(old.carId, reason.trim()));
      }
      return;
    }
    if (old != null && !old.isCatalog && old.status == MyAdStatus.pending) {
      Injector.instance.notificationsRepository.publish(
        NotificationEvents.adRejected(
          carTitle: _titleOf(old),
          reason: reason,
          ownerEmail: old.ownerEmail,
          ownerPhone: old.ownerPhone,
        ),
      );
    }
  }

  /// تم بيع السيارة
  /// تم بيع السيارة (بالـ id بتاع السيارة): بتتشال من الصفحة الرئيسية
  void markSoldByCarId(String carId) {
    for (final a in _ads) {
      if (a.carId == carId) {
        markSold(a.id);
        return;
      }
    }
  }

  void markSold(String id) {
    final old = _ads.where((a) => a.id == id).firstOrNull;
    _update(id, (a) => a.copyWith(status: MyAdStatus.sold));
    if (_remote && old != null) _push(() => _api.markSold(old.carId));
  }
}
