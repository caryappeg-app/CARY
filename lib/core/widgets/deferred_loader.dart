import 'package:flutter/material.dart';

/// ويدجت ذكي للتحميل الكسول وتقسيم الحزم البرمجية (Code Splitting / Deferred Loading)
/// يقوم بتأجيل تنزيل وتنفيذ كود الصفحات الثانوية أو لوحات التحكم
/// حتى يطلبها المستخدم فعلياً، مما يقلل حجم الحزمة الأولية ووقت التنفيذ على الـ Main Thread.
class DeferredWidget extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  final Widget? placeholder;

  const DeferredWidget({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.placeholder,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  bool _loaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.loadLibrary();
      if (mounted) {
        setState(() => _loaded = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded) {
      return widget.builder();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text('حدث خطأ أثناء تحميل الصفحة، يرجى المحاولة ثانية'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _load();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    return widget.placeholder ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        );
  }
}
