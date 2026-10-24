// Data: موديل السيارة — تحويل JSON <-> Entity (أي تغيير في شكل الـ API بيتعدل هنا بس)
import '../../../../core/validation/input_sanitizer.dart';
import '../../domain/entities/car.dart';

class CarModel {
  final Map<String, dynamic> _json;
  const CarModel._(this._json);

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      CarModel._(Map<String, dynamic>.of(json));

  factory CarModel.fromEntity(Car c) => CarModel._({
        'id': c.id,
        'brand': c.brand,
        'model': c.model,
        'year': c.year,
        'price': c.price,
        'body_type': c.bodyType,
        'drive': c.drive,
        'transmission': c.transmission,
        'km': c.km,
        'image': c.image,
        'images_count': c.imagesCount,
        'images': c.images,
        'approved_price': c.approvedPrice,
        'engine': c.engine,
        'horsepower': c.horsepower,
        'traffic_unit': c.trafficUnit,
        'license': c.license,
        'exterior_color': c.exteriorColor,
        'interior_condition': c.interiorCondition,
        'exterior_condition': c.exteriorCondition,
        'paint_status': c.paintStatus,
        'gearbox_condition': c.gearboxCondition,
        'suspension_condition': c.suspensionCondition,
        'engine_problems': c.engineProblems,
        'accident_status': c.accidentStatus,
        'description': c.description,
        'negotiable': c.negotiable,
      });

  Map<String, dynamic> toJson() => Map<String, dynamic>.of(_json);

  // تنظيف أي بيانات جاية من السيرفر قبل ما تبقى Entity (HTML / أحرف خفية / أرقام سالبة)
  static String _s(Object? v, [int max = 120]) =>
      InputSanitizer.text(v, maxLength: max);
  static int _i(Object? v) => InputSanitizer.nonNegativeInt(v);

  /// Mapper: Model -> Entity
  Car toEntity() {
    final j = _json;
    final parsedImages = [
      for (final i in (j['images'] as List? ?? const []))
        if (InputSanitizer.safeImageRef(i).isNotEmpty)
          InputSanitizer.safeImageRef(i),
    ];
    final directImg = InputSanitizer.safeImageRef(j['image']);
    final mainImage = directImg.isNotEmpty
        ? directImg
        : (parsedImages.isNotEmpty ? parsedImages.first : '');

    return Car(
      id: _s(j['id']),
      brand: _s(j['brand']),
      model: _s(j['model']),
      year: _i(j['year']),
      price: _i(j['price']),
      bodyType: _s(j['body_type']),
      drive: _s(j['drive']),
      transmission: _s(j['transmission']),
      km: _i(j['km']),
      image: mainImage,
      images: parsedImages,
      imagesCount: j['images_count'] == null
          ? (parsedImages.isNotEmpty ? parsedImages.length : 1)
          : _i(j['images_count']).clamp(1, 50),
      approvedPrice: j['approved_price'] as bool? ?? true,
      engine: _s(j['engine']),
      horsepower: _s(j['horsepower']),
      trafficUnit: _s(j['traffic_unit']),
      license: _s(j['license']),
      exteriorColor: _s(j['exterior_color']),
      interiorCondition: _s(j['interior_condition']),
      exteriorCondition: _s(j['exterior_condition']),
      paintStatus: _s(j['paint_status']),
      gearboxCondition: _s(j['gearbox_condition']),
      suspensionCondition: _s(j['suspension_condition']),
      engineProblems: _s(j['engine_problems']),
      accidentStatus: _s(j['accident_status']),
      description: _s(j['description'], 1500),
      negotiable: j['negotiable'] as bool? ?? false,
    );
  }
}

/// صفحة من الموديلات + إجمالي النتايج (شكل رد الـ API)
class CarsPageModel {
  final List<CarModel> items;
  final int total;
  const CarsPageModel({required this.items, required this.total});
}
