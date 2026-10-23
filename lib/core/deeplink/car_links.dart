// Core: بناء وقراءة روابط السيارات.
//   مشاركة:  https://<دومين>/car/<id>
//   بديل:    cary://car/<id>
import '../config/app_config.dart';

class CarLinks {
  CarLinks._();

  static Uri get _base => Uri.parse(AppConfig.shareLinkBase);

  /// الرابط اللي بيتبعت في المشاركة
  static String build(String carId) =>
      _base.replace(path: '/car/${Uri.encodeComponent(carId)}').toString();

  /// بيرجّع id السيارة لو الرابط يخص التطبيق، وإلا null
  static String? parse(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    String? id;
    if (uri.scheme == 'cary' && uri.host == 'car' && segs.isNotEmpty) {
      id = segs.first; // cary://car/ID
    } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == _base.host &&
        segs.length >= 2 &&
        segs.first == 'car') {
      id = segs[1]; // https://host/car/ID
    }
    if (id == null || id.isEmpty || id.length > 80) return null;
    return id;
  }
}
