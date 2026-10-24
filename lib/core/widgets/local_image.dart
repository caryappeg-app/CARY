import 'package:cached_network_image/cached_network_image.dart';
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

    final trimmed = path.trim();
    if (trimmed.isEmpty) return fallback;

    if (trimmed.startsWith('assets/')) {
      return Image.asset(trimmed, fit: fit, errorBuilder: broken);
    }
    final safeUrl = trimmed.startsWith('http://')
        ? 'https://${trimmed.substring(7)}'
        : trimmed;

    if (safeUrl.startsWith('http://') || safeUrl.startsWith('https://')) {
      if (kIsWeb) {
        return Image.network(
          safeUrl,
          fit: fit,
          errorBuilder: broken,
        );
      }
      return CachedNetworkImage(
        imageUrl: safeUrl,
        fit: fit,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }
    if (trimmed.startsWith('blob:')) {
      return Image.network(trimmed, fit: fit, errorBuilder: broken);
    }
    // مسار ملف محلي على الهاتف (مثلاً: /data/user/0/... أو C:\...)
    if (trimmed.startsWith('/') || trimmed.contains(':\\')) {
      if (kIsWeb) {
        // على الويب لا يمكن قراءة ملفات جهاز المستخدم، بنجرّب اسم الملف في الأصول كبديل
        final name = trimmed.split(RegExp(r'[/\\]')).last;
        return Image.asset(
          'assets/images/$name',
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
      return fileImageWidget(trimmed, fit: fit, errorBuilder: broken);
    }
    // اسم ملف عادي بدون مسار مثلاً: "camry.png"
    return Image.asset(
      trimmed.contains('/') ? trimmed : 'assets/images/$trimmed',
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
