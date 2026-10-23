import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';
import '../core/utils/date_format.dart';
import '../core/utils/formatters.dart' show formatNumber;
import '../core/widgets/date_info_row.dart';
import '../core/widgets/local_image.dart';
import 'my_ad.dart';

/// تاب "إعلاناتي": لوحة تحكم البائع (إحصائيات + فلاتر + كروت الإعلانات).
class MyAdsTab extends StatefulWidget {
  final List<MyAd> ads;
  final VoidCallback onBack;
  final VoidCallback onAddNew;
  final ValueChanged<MyAd> onSold;
  final ValueChanged<MyAd>? onOpen;

  const MyAdsTab({
    super.key,
    required this.ads,
    required this.onBack,
    required this.onAddNew,
    required this.onSold,
    this.onOpen,
  });

  @override
  State<MyAdsTab> createState() => _MyAdsTabState();
}

class _MyAdsTabState extends State<MyAdsTab> {
  static Color get _amber => AppColors.tone(0xFFF5B800);
  static Color get _amberText => AppColors.tone(0xFF9A5B00);
  static Color get _green => AppColors.tone(0xFF10B981);
  static Color get _greenText => AppColors.tone(0xFF0B7A4B);

  /// null = الكل
  MyAdStatus? _filter;

  int _count(MyAdStatus s) => widget.ads.where((a) => a.status == s).length;

  @override
  Widget build(BuildContext context) {
    final pending = _count(MyAdStatus.pending);
    final approved = _count(MyAdStatus.approved);
    final rejected = _count(MyAdStatus.rejected);
    final shown = _filter == null
        ? widget.ads
        : widget.ads.where((a) => a.status == _filter).toList();

    return Column(
      children: [
        _buildHeader(pending),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'تم المراجعة بنجاح',
                      count: approved,
                      labelColor: _greenText,
                      iconBg: AppColors.tone(0xFFD9F8E8),
                      iconColor: _green,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'قيد المراجعة',
                      count: pending,
                      labelColor: _amberText,
                      iconBg: AppColors.tone(0xFFFFEFC2),
                      iconColor: AppColors.tone(0xFFD97706),
                      icon: Icons.hourglass_bottom_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      text: 'الكل (${widget.ads.length})',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      text: 'قيد المراجعة ($pending)',
                      dot: _amber,
                      color: _amberText,
                      borderColor: AppColors.tone(0xFFF5DFA0),
                      selected: _filter == MyAdStatus.pending,
                      onTap: () =>
                          setState(() => _filter = MyAdStatus.pending),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      text: 'تم المراجعة بنجاح ($approved)',
                      dot: _green,
                      color: _greenText,
                      borderColor: AppColors.tone(0xFFA7E8C6),
                      selected: _filter == MyAdStatus.approved,
                      onTap: () =>
                          setState(() => _filter = MyAdStatus.approved),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      text: 'مرفوضة ($rejected)',
                      dot: AppColors.error,
                      color: AppColors.errorText,
                      borderColor: AppColors.errorBorder,
                      selected: _filter == MyAdStatus.rejected,
                      onTap: () =>
                          setState(() => _filter = MyAdStatus.rejected),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (shown.isEmpty)
                _buildEmpty()
              else
                for (final ad in shown) ...[
                  _AdCard(
                    ad: ad,
                    onOpen: () => widget.onOpen?.call(ad),
                    onSold: () => _confirmSold(ad),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- header
  Widget _buildHeader(int pending) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(14, 10 + topInset, 14, 12),
      child: Row(
        children: [
          _SquareButton(
            icon: Icons.arrow_forward_rounded,
            onTap: widget.onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_filled_rounded,
                          color: AppColors.blue, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'لوحة تحكم البائع • CARY',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'إعلاناتي المعروضة',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),


          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: widget.onAddNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.blue.withOpacity(0.35),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 24),
                  SizedBox(width: 4),
                  Text('إعلان جديد',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- empty
  Widget _buildEmpty() {
    final hasAds = widget.ads.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.tone(0xFFE3EAF3)),
      ),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.tone(0xFFEFF5FF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_filled_rounded,
                color: AppColors.blue, size: 44),
          ),
          const SizedBox(height: 22),
          Text(
            'لا توجد إعلانات مطابقة',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasAds
                ? 'مفيش إعلانات في الحالة دي دلوقتي.'
                : 'لم تقم بإضافة سيارات للعرض حتى الآن. اعرض سيارتك مع CARY لتحصل على أعلى سعر وفحص معتمد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.subtitle,
            ),
          ),
          if (!hasAds) ...[
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: widget.onAddNew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.blue.withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  'أضف سيارة للبيع الآن',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- sold
  Future<void> _confirmSold(MyAd ad) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: ThemeController.barrierColor,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد البيع',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('هل تم بيع ${ad.title}؟ هيتم حذف الإعلان من قائمتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تم البيع',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) widget.onSold(ad);
  }
}

// =============================================================================
// Widgets
// =============================================================================

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _SquareButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tone(0xFFF1F4F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.title, size: 25),
              if (showDot)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.badge,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color labelColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.labelColor,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tone(0xFFE3EAF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
  final Color color;
  final Color borderColor;

  const _FilterChip({
    required this.text,
    required this.selected,
    required this.onTap,
    this.dot,
    this.color = Colors.white,
    this.borderColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final isAll = dot == null;
    final bg = selected
        ? (isAll ? AppColors.blue : color.withOpacity(0.12))
        : AppColors.surface;
    final fg = isAll ? (selected ? Colors.white : AppColors.title) : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isAll ? AppColors.blue : borderColor,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final MyAd ad;
  final VoidCallback onOpen;
  final VoidCallback onSold;

  const _AdCard({
    required this.ad,
    required this.onOpen,
    required this.onSold,
  });

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
    return 'منذ ${d.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final pending = ad.status == MyAdStatus.pending;
    final rejected = ad.status == MyAdStatus.rejected;
    final border = rejected
        ? AppColors.errorBorder
        : pending
        ? AppColors.tone(0xFFF5DFA0)
        : AppColors.tone(0xFFA7E8C6);
    final stripBg = rejected
        ? AppColors.errorBg
        : pending
        ? AppColors.tone(0xFFFFF8E6)
        : AppColors.tone(0xFFECFDF5);
    final stripFg = rejected
        ? AppColors.errorText
        : pending
        ? AppColors.tone(0xFF9A5B00)
        : AppColors.tone(0xFF0B7A4B);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط الحالة
          Container(
            color: stripBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  rejected
                      ? Icons.cancel_rounded
                      : pending
                      ? Icons.hourglass_bottom_rounded
                      : Icons.check_circle_rounded,
                  color: stripFg,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      rejected
                          ? 'تم رفض الإعلان'
                          : pending
                          ? 'قيد المراجعة والتدقيق'
                          : 'تم المراجعة بنجاح',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: stripFg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_ago(ad.createdAt)} (${rejected ? 'مرفوض' : pending ? 'قيد المراجعة' : 'معتمد'})',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ),
          ),

          // محتوى الإعلان
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(),
                const SizedBox(width: 12),
                Expanded(child: _buildInfo()),
              ],
            ),
          ),

          // تاريخ ووقت رفع الإعلان + تاريخ ووقت قبوله
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DateInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'تاريخ رفع الإعلان',
                  value: formatDateTime(ad.createdAt),
                ),
                if (ad.approvedAt != null)
                  DateInfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'تاريخ القبول',
                    value: formatDateTime(ad.approvedAt!),
                    color: AppColors.tone(0xFF16A34A),
                  )
                else if (pending)
                  const DateInfoRow(
                    icon: Icons.hourglass_empty_rounded,
                    label: 'تاريخ القبول',
                    value: 'في انتظار المراجعة',
                  ),
              ],
            ),
          ),

          // الفوتر
          Container(
            decoration: BoxDecoration(
              color: AppColors.tone(0xFFFAFBFD),
              border: Border(top: BorderSide(color: AppColors.tone(0xFFEDF1F6))),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rejected
                            ? 'لم تتم الموافقة على هذا الإعلان'
                            : pending
                            ? 'جاري تدقيق البيانات الفنية من مستشار CARY'
                            : 'تم اعتماد الإعلان وهو معروض الآن للعملاء',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.subtitle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.icon, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!rejected)
                      Flexible(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: onSold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tone(0xFF0E9F6E),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: AppColors.tone(0xFF0E9F6E)
                                  .withOpacity(0.35),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sell_outlined, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'تم بيع السيارة',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!rejected) const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: rejected
                            ? AppColors.errorBg
                            : pending
                            ? AppColors.tone(0xFFFFEFC2)
                            : AppColors.tone(0xFFD9F8E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rejected ? 'مرفوض' : pending ? 'فحص جاري' : 'معتمد',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: stripFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final fallback = ColoredBox(
      color: AppColors.tone(0xFFE5EAF2),
      child: Center(
        child: Icon(Icons.directions_car_filled_outlined,
            color: AppColors.icon, size: 36),
      ),
    );

    return SizedBox(
      width: 128,
      height: 124,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LocalImage(path: ad.imagePath, fallback: fallback),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${ad.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ad.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
            ),
            if (ad.brandLogoUrl.isNotEmpty) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 26,
                height: 26,
                child: Image.network(
                  ad.brandLogoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            [
              '${formatNumber(ad.km)} كم',
              ad.transmission,
              if (ad.location.isNotEmpty) ad.location,
            ].join('  •  '),
            maxLines: 1,
            style: TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: AppColors.tone(0xFFEDF1F6),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      formatNumber(ad.price),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                  Text(
                    'ج.م',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // "عرض وتعديل": شغّال بس والإعلان قيد المراجعة
            Opacity(
              opacity: ad.status == MyAdStatus.pending ? 1 : 0.45,
              child: Material(
                color: AppColors.tileBg,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: ad.status == MyAdStatus.pending ? onOpen : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض\nوتعديل',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blue,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_back_rounded,
                            color: AppColors.blue, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}