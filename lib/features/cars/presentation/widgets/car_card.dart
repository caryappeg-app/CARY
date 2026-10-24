import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cross_file_image.dart';
import '../../domain/entities/car.dart';
import '../../../../screens/car_brand.dart';
class CarCard extends StatelessWidget {
  final Car car;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onDetails;

  /// زرار الحذف (بيظهر في حجوزاتي بس)
  final VoidCallback? onDelete;

  /// false = السيارة اتباعت/اتحذفت: بنعلّم عليها وبنقفل زرار التفاصيل والحجز
  final bool available;

  /// السعر اللي المستخدم قدّمه (بيظهر في حجوزاتي بس)
  final int? offerPrice;

  const CarCard({
    super.key,
    required this.car,
    required this.isFavorite,
    required this.onFavorite,
    required this.onDetails,
    this.onDelete,
    this.available = true,
    this.offerPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImage(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (offerPrice != null) ...[
                  const SizedBox(height: 10),
                  _buildOffer(offerPrice!),
                ],
                const SizedBox(height: 12),
                _buildSpecs(),
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ---------------------------------------------------------------- image
  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 2.1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // أول صورة من صور الإعلان (assets / رابط / ملف على الجهاز)
          // الضغط على الصورة بيفتح التفاصيل (زي زرار "عرض التفاصيل")
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: available ? onDetails : null, // نفس شرط زرار التفاصيل
            child: CarImageView(car: car),
          ),
          if (!available)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'غير متاحة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          if (car.approvedPrice)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'سعر نهائي معتمد',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
            ),
          // ✅ نفس شكل شارة "سعر نهائي معتمد" لكن للسيارات القابلة للتفاوض
          if (car.canNegotiate)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'قابل للتفاوض',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_camera_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '1/${car.imagesCount}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- offer
  /// السعر اللي المستخدم كتبه في "قدم عرض سعرك"
  Widget _buildOffer(int offer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined, color: AppColors.blue, size: 19),
          const SizedBox(width: 6),
          Text(
            'عرضك المقدم',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const Spacer(),
          Text(
            '${formatNumber(offer)} ج.م',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // يمين: السعر
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatNumber(car.price),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
              ),
            ),
            Text(
              'جنيه مصري',
              style: TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // لوجو الماركة
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: Colors.white, // خلفية اللوجو بيضا حتى في الوضع الداكن
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.tone(0xFFE8ECF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: BrandLogo(brandName: car.brand)),
        ),
        const SizedBox(width: 8),
        // الاسم والتفاصيل
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                car.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                car.subtitle,
                style: TextStyle(fontSize: 13, color: AppColors.subtitle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- specs
  Widget _buildSpecs() {
    return Row(
      children: [
        Expanded(
          child: _SpecTile(
            icon: Icons.calendar_today_outlined,
            value: '${car.year}',
            label: 'سنة الصنع',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SpecTile(
            icon: Icons.settings_outlined,
            value: car.transmission,
            label: 'ناقل الحركة',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SpecTile(
            icon: Icons.speed_rounded,
            value: '${formatNumber(car.km)} كم',
            label: 'العداد الفعلي',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- actions
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: available ? onDetails : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.blue.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 21),
                    SizedBox(width: 8),
                    Text(
                      'عرض التفاصيل وحجز السيارة',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          Material(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onDelete,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.delete_outline_rounded,
                    size: 24, color: AppColors.error),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Material(
          color: AppColors.tileBg,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onFavorite,
            child: SizedBox(
              width: 48,
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isFavorite),
                  size: 24,
                  color: isFavorite ? AppColors.badge : AppColors.subtitle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// صورة السيارة مع تجربة المسارات البديلة (تُستخدم في الكارت وشاشة التفاصيل)
class CarImageView extends StatelessWidget {
  final Car car;
  final BoxFit fit;

  /// مسار صورة معيّنة (لو null بنستخدم الصورة الرئيسية للسيارة)
  final String? path;
  const CarImageView(
      {super.key, required this.car, this.fit = BoxFit.cover, this.path});

  List<String> get _candidates {
    final img = path ?? car.image;
    final name = img.split('/').last;
    return {img, 'assets/images/$name', 'assets/$name'}.toList();
  }

  Widget _build(List<String> candidates, int index) {
    if (index >= candidates.length) {
      debugPrint('CarImageView: الصورة مش لاقيها في: $candidates');
      return Container(
        color: AppColors.tone(0xFFE5EAF2),
        alignment: Alignment.center,
        child: Icon(Icons.directions_car_filled_outlined,
            size: 64, color: AppColors.icon),
      );
    }
    final path = candidates[index];
    Widget next(Object _, StackTrace? __) => _build(candidates, index + 1);
    if (path.startsWith('http')) {
      // كاش على الذاكرة والتخزين: الصورة بتتحمّل مرة واحدة بس، وبتتفك بحجم الشاشة
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        memCacheWidth: 900,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
        errorWidget: (_, __, e) => next(e, null),
      );
    }
    // رابط blob (الويب) أو مسار ملف على الجهاز (صور الإعلانات اللي المستخدم رفعها)
    if (path.startsWith('blob:')) {
      return Image.network(path,
          fit: fit, errorBuilder: (c, e, s) => next(e, s));
    }
    if (path.startsWith('/') || path.contains(':\\')) {
      if (kIsWeb) return next('web', null);
      return fileImageWidget(path,
          fit: fit, errorBuilder: (c, e, s) => next(e, s));
    }
    return Image.asset(path, fit: fit, errorBuilder: (c, e, s) => next(e, s));
  }

  @override
  Widget build(BuildContext context) =>
      _build(_candidates, 0);
}

/// لوجو الماركة (من ملف الجايسون) — لو مش لاقيه بيعرض أيقونة سيارة
class BrandLogo extends StatefulWidget {
  final String brandName;
  const BrandLogo({super.key, required this.brandName});

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> {
  late Future<CarBrand?> _future = CarBrand.findFor(widget.brandName);

  @override
  void didUpdateWidget(covariant BrandLogo old) {
    super.didUpdateWidget(old);
    if (old.brandName != widget.brandName) {
      _future = CarBrand.findFor(widget.brandName);
    }
  }

  static Widget get _fallback => Icon(Icons.directions_car_filled_outlined,
      color: AppColors.icon, size: 26);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CarBrand?>(
      future: _future,
      builder: (context, snap) {
        final url = snap.data?.logoUrl ?? '';
        if (url.isEmpty) return _fallback;
        return Padding(
          padding: const EdgeInsets.all(7),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fallback,
          ),
        );
      },
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SpecTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}