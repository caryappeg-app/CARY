// Presentation: بيفتح بيانات السيارة أوتوماتيك لما يجي رابط مشاركة.
// لازم يتحط جوه الـ MultiBlocProvider بتاع HomeScreen (محتاج Favorites/Bookings/Account).
import 'package:flutter/material.dart';

import '../../../../core/deeplink/deep_link_service.dart';
import '../../../../core/di/injection.dart';
import '../pages/open_car_details.dart';

class CarLinkListener extends StatefulWidget {
  final Widget child;
  final VoidCallback onBooked;
  const CarLinkListener({super.key, required this.child, required this.onBooked});

  @override
  State<CarLinkListener> createState() => _CarLinkListenerState();
}

class _CarLinkListenerState extends State<CarLinkListener> {
  final _service = DeepLinkService.instance;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _service.pendingCarId.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _service.pendingCarId.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    if (_opening || !mounted || _service.pendingCarId.value == null) return;
    _opening = true;
    final id = _service.consume()!;
    try {
      final car = await Injector.instance.carRepository.getCarById(id);
      if (!mounted) return;
      if (car == null) {
        _snack('الإعلان ده مش متاح دلوقتي (ممكن يكون اتباع أو اتحذف)');
      } else {
        // نرجع لأول شاشة (HomeScreen) لو في شاشات مفتوحة فوقها
        Navigator.of(context).popUntil((r) => r.isFirst);
        openCarDetails(context, car, onBooked: widget.onBooked);
      }
    } catch (_) {
      if (mounted) _snack('تعذّر فتح الإعلان، جرّب تاني');
    } finally {
      _opening = false;
      // لو جه رابط تاني أثناء الفتح
      if (mounted && _service.pendingCarId.value != null) _check();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) => widget.child;
}
