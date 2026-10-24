// Domain: كيان السيارة (Dart صافي — مفيش أي اعتماد على Flutter أو الداتا)

class Car {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int price;
  final String bodyType;
  final String drive;
  final String transmission;
  final int km;
  final String image;
  final int imagesCount;

  /// كل صور السيارة (لو فاضية بنستخدم [image] بس)
  final List<String> images;
  final bool approvedPrice;

  // ---- تفاصيل إضافية (بتظهر في شاشة التفاصيل والحجز)
  /// سعة المحرك كنص حر (أرقام ونصوص): "1600 CC تيربو"، "1.6L"، "كهرباء"...
  final String engine;
  final String horsepower; // مثال: "180 حصان"
  final String trafficUnit; // وحدة المرور
  final String license; // رخصة السيارة
  final String exteriorColor; // اللون الخارجي
  final String interiorCondition; // حالة الداخلية
  final String exteriorCondition; // الحالة الخارجية
  final String paintStatus; // هل تم دهان السيارة؟
  final String gearboxCondition; // حالة ناقل الحركة
  final String suspensionCondition; // حالة العفشة
  final String engineProblems; // هل يوجد أي مشاكل في الموتور؟ (نعم / لا)
  final String accidentStatus; // هل يوجد بالسيارة أي حوادث؟
  final String description; // الوصف وتقرير الحالة
  final bool negotiable; // قابل للتفاوض البسيط

  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    required this.bodyType,
    required this.drive,
    required this.transmission,
    required this.km,
    required this.image,
    this.imagesCount = 1,
    this.images = const [],
    this.approvedPrice = true,
    this.engine = '',
    this.horsepower = '',
    this.trafficUnit = '',
    this.license = '',
    this.exteriorColor = '',
    this.interiorCondition = '',
    this.exteriorCondition = '',
    this.paintStatus = '',
    this.gearboxCondition = '',
    this.suspensionCondition = '',
    this.engineProblems = '',
    this.accidentStatus = '',
    this.description = '',
    this.negotiable = false,
  });

  /// الصور اللي بتتعرض في الشاشة (الأولى هي الرئيسية)
  List<String> get allImages {
    if (images.isNotEmpty) return images;
    if (image.isNotEmpty) return [image];
    return const [];
  }

  /// التفاوض متاح بس لو السيارة قابلة للتفاوض وسعرها مش "نهائي معتمد"
  bool get canNegotiate => negotiable && !approvedPrice;

  String get title => '$brand $model موديل $year';
  String get subtitle => 'فئة $bodyType • $drive';

  /// سطر المواصفات في شاشة التفاصيل: فئة SUV • 1600 CC تيربو (180 حصان)
  String get specsLine {
    final parts = <String>['فئة $bodyType'];
    if (engine.isNotEmpty) parts.add(engine);
    var s = parts.join(' • ');
    if (horsepower.isNotEmpty) s += ' ($horsepower)';
    return s;
  }

  @override
  bool operator ==(Object other) => other is Car && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
