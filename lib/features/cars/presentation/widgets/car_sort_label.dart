// Presentation: نصوص الترتيب بالعربي (الـ Domain مبيعرفش حاجة عن النصوص دي)
import '../../domain/entities/car_sort.dart';

extension CarSortLabel on CarSort {
  String get label {
    switch (this) {
      case CarSort.defaultOrder:
        return 'الافتراضي';
      case CarSort.priceAsc:
        return 'السعر: الأقل أولاً';
      case CarSort.priceDesc:
        return 'السعر: الأعلى أولاً';
      case CarSort.yearDesc:
        return 'الأحدث';
      case CarSort.kmAsc:
        return 'الأقل كيلومترات';
    }
  }
}
