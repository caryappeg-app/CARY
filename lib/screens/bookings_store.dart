import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/di/injection.dart';
import '../features/account/domain/entities/user_profile.dart';
import '../features/cars/data/models/car_model.dart';
import '../features/cars/domain/entities/car.dart';
import '../features/notifications/domain/entities/app_notification.dart';
import 'ads_store.dart';

/// حالة الحجز في "إدارة الحجوزات"
enum ManagedBookingStatus {
  /// حجز نشط (لسه العملية ما خلصتش)
  active,

  /// عملية ناجحة
  success,

  /// عملية فاشلة
  failed,
}

/// حجز واحد بكل أطرافه: السيارة + المشتري + البائع + السعر المقترح
class ManagedBooking {
  final String id;
  final Car car;

  /// السعر اللي المشتري طلبه (null = حجز بدون تفاوض)
  final int? offerPrice;

  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;

  final String sellerName;
  final String sellerPhone;
  final String sellerEmail;

  /// تاريخ ووقت طلب الحجز
  final DateTime createdAt;

  /// تاريخ ووقت نجاح أو فشل العملية (null = لسه نشط)
  final DateTime? completedAt;
  final ManagedBookingStatus status;

  /// بيانات العملية الناجحة (بتتسجل لما الأدمن/المالك يضغط "نجحت العملية")
  final int? buyerPaid; // المبلغ اللي دفعه المشتري
  final int? sellerReceived; // المبلغ اللي استلمه البائع
  final int? commission; // العمولة

  const ManagedBooking({
    required this.id,
    required this.car,
    this.offerPrice,
    this.buyerName = '',
    this.buyerPhone = '',
    this.buyerEmail = '',
    this.sellerName = '',
    this.sellerPhone = '',
    this.sellerEmail = '',
    required this.createdAt,
    this.completedAt,
    this.status = ManagedBookingStatus.active,
    this.buyerPaid,
    this.sellerReceived,
    this.commission,
  });

  ManagedBooking copyWith({
    ManagedBookingStatus? status,
    DateTime? completedAt,
    int? buyerPaid,
    int? sellerReceived,
    int? commission,
  }) {
    // وقت إنهاء العملية بيتسجل تلقائي أول ما الحالة تتحوّل لناجحة/فاشلة
    DateTime? nextCompleted = completedAt ?? this.completedAt;
    if (completedAt == null && status != null && status != this.status) {
      nextCompleted =
          status == ManagedBookingStatus.active ? null : DateTime.now();
    }
    return ManagedBooking(
        id: id,
        car: car,
        offerPrice: offerPrice,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerEmail: buyerEmail,
        sellerName: sellerName,
        sellerPhone: sellerPhone,
        sellerEmail: sellerEmail,
        createdAt: createdAt,
        completedAt: nextCompleted,
        status: status ?? this.status,
        buyerPaid: buyerPaid ?? this.buyerPaid,
        sellerReceived: sellerReceived ?? this.sellerReceived,
        commission: commission ?? this.commission,
      );
  }
}

/// مخزن الحجوزات لشاشة "إدارة الحجوزات" (أدمن / مالك).
/// مرتبط مباشرة بسيرفر Supabase لجلب وتحديث حجوزات كافة المستخدمين.
class BookingsAdminStore extends ChangeNotifier {
  BookingsAdminStore._();
  static final BookingsAdminStore instance = BookingsAdminStore._();

  final List<ManagedBooking> _items = [];

  bool get _remote => AppConfig.useBackend;

  /// تحميل كافة الحجوزات من السيرفر (للأدمن والمالك)
  Future<void> loadFromServer({bool force = false}) async {
    if (!_remote) return;
    try {
      final client = Injector.instance.apiClient;

      List<dynamic>? rows;
      // محاولة 1: استدعاء RPC list_bookings المخصصة للإدارة
      try {
        final res =
            await client.post('/rest/v1/rpc/list_bookings', body: const {});
        if (res is List) rows = res;
      } catch (_) {}

      // محاولة 2: قراءة جدول bookings مباشرة مع العلاقات car و buyer
      if (rows == null) {
        try {
          final res = await client.get(
              '/rest/v1/bookings?select=*,car:cars(*),buyer:profiles(*)&order=created_at.desc');
          if (res is List) rows = res;
        } catch (_) {}
      }

      // محاولة 3: قراءة جدول bookings مباشرة
      if (rows == null) {
        try {
          final res =
              await client.get('/rest/v1/bookings?select=*&order=created_at.desc');
          if (res is List) rows = res;
        } catch (_) {}
      }

      if (rows == null) return;

      // سحب بيانات البروفايلات لربط buyer_id بالاسم ورقم الهاتف
      final Map<String, Map<String, dynamic>> profilesMap = {};
      try {
        final pRes = await client
            .get('/rest/v1/profiles?select=id,full_name,email,phone');
        if (pRes is List) {
          for (final p in pRes.whereType<Map>()) {
            final pid = p['id']?.toString() ?? '';
            if (pid.isNotEmpty) profilesMap[pid] = Map<String, dynamic>.from(p);
          }
        }
      } catch (_) {}

      final parsed = <ManagedBooking>[];
      for (final r in rows.whereType<Map>()) {
        final row = Map<String, dynamic>.from(r);
        final buyerId = (row['buyer_id'] ?? '').toString();
        if (row['buyer'] == null && profilesMap.containsKey(buyerId)) {
          row['buyer'] = profilesMap[buyerId];
        }
        parsed.add(_fromRow(row));
      }

      _items
        ..clear()
        ..addAll(parsed);
      notifyListeners();

      // سحب تفاصيل السيارات الناقصة تلقائياً من CarRepository
      var updatedCars = false;
      for (var i = 0; i < _items.length; i++) {
        final b = _items[i];
        if ((b.car.brand.isEmpty || b.car.model.isEmpty) && b.car.id.isNotEmpty) {
          try {
            final c = await Injector.instance.carRepository.getCarById(b.car.id);
            if (c != null) {
              var sName = b.sellerName;
              var sPhone = b.sellerPhone;
              var sEmail = b.sellerEmail;
              final ad = AdsStore.instance.all
                  .where((a) => a.carId == c.id)
                  .firstOrNull;
              if (ad != null && sName.isEmpty) {
                sName = ad.ownerName;
                sPhone = ad.ownerPhone;
                sEmail = ad.ownerEmail;
              }
              _items[i] = ManagedBooking(
                id: b.id,
                car: c,
                offerPrice: b.offerPrice,
                buyerName: b.buyerName,
                buyerPhone: b.buyerPhone,
                buyerEmail: b.buyerEmail,
                sellerName: sName,
                sellerPhone: sPhone,
                sellerEmail: sEmail,
                createdAt: b.createdAt,
                completedAt: b.completedAt,
                status: b.status,
                buyerPaid: b.buyerPaid,
                sellerReceived: b.sellerReceived,
                commission: b.commission,
              );
              updatedCars = true;
            }
          } catch (_) {}
        }
      }
      if (updatedCars) notifyListeners();
    } catch (e) {
      debugPrint('BookingsAdminStore.loadFromServer error: $e');
    }
  }

  static ManagedBooking _fromRow(Map<String, dynamic> m) {
    Car car;
    if (m['car'] is Map) {
      car = CarModel.fromJson(Map<String, dynamic>.from(m['car'] as Map))
          .toEntity();
    } else {
      final carId = (m['car_id'] ?? m['carId'] ?? '').toString();
      final fromAds =
          AdsStore.instance.all.where((a) => a.carId == carId).firstOrNull;
      if (fromAds != null) {
        car = fromAds.toCar();
      } else {
        car = Car(
          id: carId,
          brand: (m['brand'] ?? '').toString(),
          model: (m['model'] ?? '').toString(),
          year: int.tryParse(m['year']?.toString() ?? '') ?? 0,
          price: int.tryParse(m['price']?.toString() ?? '') ?? 0,
          bodyType: (m['body_type'] ?? '').toString(),
          drive: (m['drive'] ?? '').toString(),
          transmission: (m['transmission'] ?? '').toString(),
          km: int.tryParse(m['km']?.toString() ?? '') ?? 0,
          image: (m['image'] ?? '').toString(),
          images:
              (m['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        );
      }
    }

    final buyer =
        m['buyer'] is Map ? Map<String, dynamic>.from(m['buyer'] as Map) : null;
    final buyerName =
        (m['buyer_name'] ?? buyer?['full_name'] ?? '').toString();
    final buyerPhone = (m['buyer_phone'] ?? buyer?['phone'] ?? '').toString();
    final buyerEmail = (m['buyer_email'] ?? buyer?['email'] ?? '').toString();

    final seller = m['seller'] is Map
        ? Map<String, dynamic>.from(m['seller'] as Map)
        : null;
    String sellerName =
        (m['seller_name'] ?? seller?['full_name'] ?? '').toString();
    String sellerPhone =
        (m['seller_phone'] ?? seller?['phone'] ?? '').toString();
    String sellerEmail =
        (m['seller_email'] ?? seller?['email'] ?? '').toString();

    if (sellerName.isEmpty && sellerPhone.isEmpty && sellerEmail.isEmpty) {
      final ad =
          AdsStore.instance.all.where((a) => a.carId == car.id).firstOrNull;
      if (ad != null) {
        sellerName = ad.ownerName;
        sellerPhone = ad.ownerPhone;
        sellerEmail = ad.ownerEmail;
      }
    }

    final statusStr = (m['status'] ?? 'active').toString().toLowerCase();
    final status = switch (statusStr) {
      'success' => ManagedBookingStatus.success,
      'failed' => ManagedBookingStatus.failed,
      _ => ManagedBookingStatus.active,
    };

    return ManagedBooking(
      id: (m['id'] ?? '').toString(),
      car: car,
      offerPrice: (m['offer_price'] as num?)?.toInt(),
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      sellerEmail: sellerEmail,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      completedAt:
          DateTime.tryParse(m['completed_at']?.toString() ?? '')?.toLocal(),
      status: status,
      buyerPaid: (m['buyer_paid'] as num?)?.toInt(),
      sellerReceived: (m['seller_received'] as num?)?.toInt(),
      commission: (m['commission'] as num?)?.toInt(),
    );
  }

  List<ManagedBooking> byStatus(ManagedBookingStatus s) =>
      _items.where((b) => b.status == s).toList();

  int count(ManagedBookingStatus s) =>
      _items.where((b) => b.status == s).length;

  /// تسجيل حجز جديد (بيتنادى بعد تأكيد الحجز / إرسال عرض السعر).
  /// المشتري = المستخدم الحالي، والبائع = صاحب الإعلان (من مخزن الإعلانات).
  void record({
    required Car car,
    int? offerPrice,
    UserProfile? buyer,
  }) {
    MyAdOwner seller = const MyAdOwner();
    for (final a in AdsStore.instance.all) {
      if (a.carId == car.id) {
        seller = MyAdOwner(a.ownerName, a.ownerPhone, a.ownerEmail);
        break;
      }
    }

    final email = buyer?.email ?? '';
    // نفس المشتري على نفس السيارة وهو لسه نشط: نحدّث الحجز بدل ما نكرّره
    _items.removeWhere((b) =>
        b.status == ManagedBookingStatus.active &&
        b.car.id == car.id &&
        b.buyerEmail == email);

    _items.insert(
      0,
      ManagedBooking(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        car: car,
        offerPrice: offerPrice,
        buyerName: buyer?.fullName ?? '',
        buyerPhone: buyer?.phone ?? '',
        buyerEmail: email,
        sellerName: seller.name,
        sellerPhone: seller.phone,
        sellerEmail: seller.email,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    // إشعار للأدمن والمالك: مستخدم حجز سيارة
    Injector.instance.notificationsRepository.publish(
      NotificationEvents.newBooking(
        carTitle: car.title,
        buyerName: buyer?.fullName ?? '',
        offerPrice: offerPrice,
        buyerEmail: email,
      ),
    );
  }

  /// حذف حجوزات سيارة معيّنة لمشتري معيّن (لما المستخدم يحذفها من حجوزاتي)
  void removeForBuyer(String carId, String buyerEmail) {
    final before = _items.length;
    _items.removeWhere((b) => b.car.id == carId && b.buyerEmail == buyerEmail);
    if (_items.length != before) notifyListeners();
  }

  /// نجاح العملية: بنسجّل المبالغ، والسيارة بتتشال من الرئيسية (تم بيعها)،
  /// وحجوزات تانية نشطة على نفس السيارة بتبقى فاشلة. (حجز المشتري بيتشال من
  /// "حجوزاتي" من الشاشة الرئيسية اللي بتسمع للمخزن ده.)
  void completeSuccess(
    String id, {
    required int buyerPaid,
    required int sellerReceived,
    required int commission,
  }) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i == -1) return;
    final carId = _items[i].car.id;
    _items[i] = _items[i].copyWith(
      status: ManagedBookingStatus.success,
      buyerPaid: buyerPaid,
      sellerReceived: sellerReceived,
      commission: commission,
    );
    final soldTitle = _items[i].car.title;
    for (var j = 0; j < _items.length; j++) {
      if (j != i &&
          _items[j].car.id == carId &&
          _items[j].status == ManagedBookingStatus.active) {
        final other = _items[j];
        _items[j] = other.copyWith(status: ManagedBookingStatus.failed);
        // إشعار للي كان حاجز نفس السيارة: اتباعت، وده سبب اختفائها من "حجوزاتي"
        if (other.buyerEmail.isNotEmpty || other.buyerPhone.isNotEmpty) {
          Injector.instance.notificationsRepository.publish(
            NotificationEvents.carSold(
              carTitle: soldTitle,
              buyerEmail: other.buyerEmail,
              buyerPhone: other.buyerPhone,
            ),
          );
        }
      }
    }
    AdsStore.instance.markSoldByCarId(carId);
    notifyListeners();
    if (_remote) {
      unawaited(() async {
        try {
          final client = Injector.instance.apiClient;
          await client.put(
            '/rest/v1/bookings?id=eq.$id',
            body: {
              'status': 'success',
              'buyer_paid': buyerPaid,
              'seller_received': sellerReceived,
              'commission': commission,
              'completed_at': DateTime.now().toIso8601String(),
            },
          );
        } catch (_) {}
      }());
    }
  }

  /// السيارة اتحذفت أو اتباعت: أي حجز نشط عليها بيتحوّل لفاشل.
  /// [sold] = true => بنبلّغ كل اللي حاجزها إن السيارة اتباعت (سبب اختفائها من حجوزاتي).
  void failActiveForCar(String carId, {bool sold = false}) {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].car.id == carId &&
          _items[i].status == ManagedBookingStatus.active) {
        final b = _items[i];
        _items[i] = b.copyWith(status: ManagedBookingStatus.failed);
        changed = true;
        if (sold && (b.buyerEmail.isNotEmpty || b.buyerPhone.isNotEmpty)) {
          Injector.instance.notificationsRepository.publish(
            NotificationEvents.carSold(
              carTitle: b.car.title,
              buyerEmail: b.buyerEmail,
              buyerPhone: b.buyerPhone,
            ),
          );
        }
        if (_remote) {
          unawaited(() async {
            try {
              final client = Injector.instance.apiClient;
              await client.put(
                '/rest/v1/bookings?id=eq.${b.id}',
                body: {
                  'status': 'failed',
                  'completed_at': DateTime.now().toIso8601String(),
                },
              );
            } catch (_) {}
          }());
        }
      }
    }
    if (changed) notifyListeners();
  }

  void setStatus(String id, ManagedBookingStatus status) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i == -1) return;
    _items[i] = _items[i].copyWith(status: status);
    notifyListeners();
    if (_remote) {
      unawaited(() async {
        try {
          final client = Injector.instance.apiClient;
          await client.put(
            '/rest/v1/bookings?id=eq.$id',
            body: {
              'status': status.name,
              if (status != ManagedBookingStatus.active)
                'completed_at': DateTime.now().toIso8601String(),
            },
          );
        } catch (_) {}
      }());
    }
  }

  /// حذف حجز فاشل نهائياً (متاح للمالك فقط)
  Future<bool> deleteFailedBooking(String id) async {
    final i = _items.indexWhere(
        (b) => b.id == id && b.status == ManagedBookingStatus.failed);
    if (i == -1) return false;
    _items.removeAt(i);
    notifyListeners();

    if (_remote) {
      unawaited(() async {
        try {
          final client = Injector.instance.apiClient;
          await client.delete('/rest/v1/bookings?id=eq.$id');
        } catch (e) {
          debugPrint('BookingsAdminStore.deleteFailedBooking direct error: $e');
          try {
            final client = Injector.instance.apiClient;
            await client.post('/rest/v1/rpc/delete_booking', body: {'p_id': id});
          } catch (_) {}
        }
      }());
    }
    return true;
  }
}

/// بيانات صاحب الإعلان (البائع)
class MyAdOwner {
  final String name;
  final String phone;
  final String email;
  const MyAdOwner([this.name = '', this.phone = '', this.email = '']);
}
