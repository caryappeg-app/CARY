// Domain: قواعد عرض السعر — العرض لازم يكون رقم موجب وأقل من سعر السيارة
import '../../../../core/utils/formatters.dart';

class OfferRules {
  OfferRules._();

  /// بيرجّع رسالة الخطأ (بالعربي) أو null لو العرض سليم
  static String? validate({required int? offer, required int carPrice}) {
    if (offer == null) return 'اكتب السعر بالأرقام';
    if (offer <= 0) return 'اكتب سعر صحيح';
    if (offer >= carPrice) {
      return 'السعر المقترح لازم يكون أقل من سعر السيارة (${formatNumber(carPrice)} ج.م)';
    }
    return null;
  }
}
