// Core: بيسمع لروابط السيارات (التطبيق مفتوح أو مقفول) ويحفظ آخر id مستني.
// الشاشة الرئيسية (CarLinkListener) هي اللي بتفتح التفاصيل لما تكون جاهزة،
// فلو الرابط جه قبل تسجيل الدخول بيتفتح بعد الدخول.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'car_links.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  /// id السيارة المستني فتحها (null = مفيش)
  final ValueNotifier<String?> pendingCarId = ValueNotifier<String?>(null);

  StreamSubscription<Uri>? _sub;
  String? _lastId;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    if (_sub != null) return;
    try {
      final links = AppLinks();
      final initial = await links.getInitialLink();
      if (initial != null) _handle(initial);
      _sub = links.uriLinkStream.listen(_handle, onError: (_) {});
    } catch (_) {
      // المنصة مش بتدعم الروابط (مثلاً ويب/ديسكتوب) — نكمل عادي
    }
  }

  void _handle(Uri uri) {
    final id = CarLinks.parse(uri);
    if (id == null) return;
    // نفس الرابط ممكن يجي مرتين (initial + stream)
    final now = DateTime.now();
    if (id == _lastId && now.difference(_lastAt).inSeconds < 3) return;
    _lastId = id;
    _lastAt = now;
    pendingCarId.value = id;
  }

  /// بيرجّع الـ id المستني ويمسحه
  String? consume() {
    final id = pendingCarId.value;
    pendingCarId.value = null;
    return id;
  }
}
