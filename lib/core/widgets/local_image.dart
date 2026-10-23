// صورة من أي مصدر: assets / رابط (http, https, blob) / ملف على الجهاز.
// على الويب مفيش ملفات محلية، فبنستخدم Image.network (روابط blob من الـ picker).
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'cross_file_image.dart';

class LocalImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget fallback;

  const LocalImage({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget broken(BuildContext _, Object __, StackTrace? ___) => fallback;

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: fit, errorBuilder: broken);
    }
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(path, fit: fit, errorBuilder: broken);
    }
    return fileImageWidget(path, fit: fit, errorBuilder: broken);
  }
}
