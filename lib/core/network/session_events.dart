// Core: قناة أحداث بسيطة بتبلّغ التطبيق إن الجلسة انتهت (فشل تجديد التوكن).
import 'dart:async';

class SessionEvents {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get onExpired => _controller.stream;

  void notifyExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
