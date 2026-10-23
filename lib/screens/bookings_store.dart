import 'package:flutter/foundation.dart';

import '../core/di/injection.dart';
import '../features/account/domain/entities/user_profile.dart';
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

/// مخزن الحجوزات المشترك (In-Memory) لشاشة "إدارة الحجوزات" (أدمن / مالك).
/// لما الـ API يتربط يتبدّل بـ Repository.
class BookingsAdminStore extends ChangeNotifier {
  BookingsAdminStore._();
  static final BookingsAdminStore instance = BookingsAdminStore._();

  final List<ManagedBooking> _items = [];

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
      }
    }
    if (changed) notifyListeners();
  }

  void setStatus(String id, ManagedBookingStatus status) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i == -1) return;
    _items[i] = _items[i].copyWith(status: status);
    notifyListeners();
  }
}

/// بيانات صاحب الإعلان (البائع)
class MyAdOwner {
  final String name;
  final String phone;
  final String email;
  const MyAdOwner([this.name = '', this.phone = '', this.email = '']);
}
