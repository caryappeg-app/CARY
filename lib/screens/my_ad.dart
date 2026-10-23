import '../features/cars/domain/entities/car.dart';

/// حالة الإعلان
enum MyAdStatus {
  /// قيد المراجعة والتدقيق
  pending,

  /// تم المراجعة بنجاح (معروض للعملاء)
  approved,

  /// مرفوض من الإدارة (مع سبب الرفض)
  rejected,

  /// تم بيع السيارة
  sold,
}

/// إعلان من إعلانات المستخدم (بيظهر في صفحة \"إعلاناتي\" وفي \"إدارة الإعلانات\").
class MyAd {
  final String id;
  final String brandName;
  final String brandLogoUrl;
  final String model;
  final int year;
  final int km;
  final String transmission;
  final String location;
  final int price;
  final String imagePath; // مسار الصورة الرئيسية على الجهاز

  /// كل الصور اللي المستخدم أدخلها (الأولى = الرئيسية)
  final List<String> images;
  /// تاريخ ووقت إصدار الإعلان (لما اترفع وبقى قيد المراجعة)
  final DateTime createdAt;

  /// تاريخ ووقت قبول الإعلان (null = لسه ما اتقبلش)
  final DateTime? approvedAt;
  final MyAdStatus status;

  /// بيانات صاحب الحساب (اللي أضاف الإعلان)
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;

  /// تفاصيل السيارة (اسم الخانة -> القيمة) زي: نوع المحرك، اللون، الحالة...
  final Map<String, String> details;

  /// سبب الرفض (بيتكتب يدوي من الأدمن/المالك)
  final String? rejectionReason;

  /// سبب الحذف (بيتكتب من الأدمن/المالك) — غير null = الإعلان اتحذف
  final String? deletionReason;

  /// true = سيارة من الصفحة الرئيسية (معتمدة تلقائيًا ومش بتاعة مستخدم)
  final bool isCatalog;

  const MyAd({
    required this.id,
    required this.brandName,
    required this.brandLogoUrl,
    required this.model,
    required this.year,
    required this.km,
    required this.transmission,
    required this.location,
    required this.price,
    required this.imagePath,
    this.images = const [],
    required this.createdAt,
    this.approvedAt,
    this.status = MyAdStatus.pending,
    this.ownerName = '',
    this.ownerPhone = '',
    this.ownerEmail = '',
    this.details = const {},
    this.rejectionReason,
    this.deletionReason,
    this.isCatalog = false,
  });

  /// id السيارة في الرئيسية (إعلان الكتالوج بيحتفظ بـ id السيارة الأصلي،
  /// فالمفضلة والحجوزات القديمة تفضل مربوطة بيه حتى بعد التعديل)
  String get carId =>
      id.startsWith('catalog:') ? id.substring('catalog:'.length) : id;

  List<String> get allImages => images.isNotEmpty ? images : [imagePath];

  String get title => '$brandName $model $year';

  /// تحويل الإعلان لـ [Car] عشان يتعرض في شاشة تفاصيل السيارة
  Car toCar() {
    String d(String k) => details[k] ?? '';
    return Car(
      id: carId,
      brand: brandName,
      model: model,
      year: year,
      price: price,
      bodyType: d('شكل السيارة'),
      drive: d('الدفع').isNotEmpty ? d('الدفع') : d('نوع المحرك'),
      transmission: transmission,
      km: km,
      image: allImages.first,
      imagesCount: allImages.length,
      images: allImages,
      approvedPrice: false,
      engine: d('سعة المحرك'),
      horsepower: d('القوة'),
      trafficUnit: location,
      license: d('الرخصة'),
      exteriorColor: d('اللون'),
      interiorCondition: d('الداخلية'),
      exteriorCondition: d('الخارجية'),
      paintStatus: d('الدهان'),
      gearboxCondition: d('الجير'),
      suspensionCondition: d('المساعدين'),
      engineProblems: d('مشاكل المحرك'),
      accidentStatus: d('الحوادث'),
      description: d('الوصف'),
      negotiable: d('قابل للتفاوض') == 'نعم',
    );
  }

  MyAd copyWith({
    MyAdStatus? status,
    DateTime? approvedAt,
    String? rejectionReason,
    String? deletionReason,
    List<String>? images,
  }) =>
      MyAd(
        id: id,
        brandName: brandName,
        brandLogoUrl: brandLogoUrl,
        model: model,
        year: year,
        km: km,
        transmission: transmission,
        location: location,
        price: price,
        imagePath: (images != null && images.isNotEmpty) ? images.first : imagePath,
        images: images ?? this.images,
        createdAt: createdAt,
        approvedAt: approvedAt ?? this.approvedAt,
        status: status ?? this.status,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        details: details,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        deletionReason: deletionReason ?? this.deletionReason,
        isCatalog: isCatalog,
      );
}
