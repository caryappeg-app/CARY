import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/theme_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/deeplink/car_links.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/car.dart';
import '../../domain/entities/offer_rules.dart';
import '../widgets/car_card.dart' show BrandLogo, CarImageView;

/// شاشة تفاصيل السيارة والحجز — بتتفتح من زرار "عرض التفاصيل وحجز السيارة".
class CarDetailsScreen extends StatefulWidget {
  final Car car;
  final bool isFavorite;
  final VoidCallback onFavorite;

  /// وضع "عرض فقط": بيعرض تفاصيل السيارة بس — من غير حجز ولا عرض سعر
  /// ولا مفضلة (مستخدم في شاشة إدارة الإعلانات)
  final bool viewOnly;

  /// لو اتحدد: الحجز وعرض السعر بيتمنعوا ويظهر الرسالة دي (مثلاً صاحب الإعلان)
  final String? bookingBlockedMessage;

  /// لو اتحدد (مع viewOnly) بيظهر زرار "تعديل الإعلان" تحت
  final VoidCallback? onEdit;

  /// بتتنادى بعد تأكيد الحجز / طلب الشراء (الشاشة الرئيسية بتضيف السيارة
  /// في "حجوزاتي" وبتنقلك للتاب ده)
  /// (السيارة، السعر المقترح أو null) — بتتنادى بعد الحجز أو إرسال العرض
  final void Function(Car car, int? offerPrice)? onBook;

  const CarDetailsScreen({
    super.key,
    required this.car,
    this.isFavorite = false,
    this.onFavorite = _noop,
    this.onBook,
    this.viewOnly = false,
    this.onEdit,
    this.bookingBlockedMessage,
  });

  static void _noop() {}

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final _offerCtrl = TextEditingController();
  String? _offerError; // رسالة خطأ عرض السعر (null = مفيش خطأ)
  late bool _fav = widget.isFavorite;
  int _page = 0; // رقم الصورة الحالية في المعرض

  Car? _full; // النسخة الكاملة (كل الصور + الوصف) بعد تحميلها من السيرفر
  Car get car => _full ?? widget.car;

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  /// قايمة الرئيسية بتجيب أول صورة بس (أسرع وأوفر في الداتا)؛ هنا بنجيب الباقي
  Future<void> _loadFull() async {
    final c = widget.car;
    if (!AppConfig.useBackend) return;
    if (c.images.length >= c.imagesCount && c.description.isNotEmpty) return;
    try {
      final full = await Injector.instance.carRepository.getCarById(c.id);
      if (!mounted || full == null) return;
      setState(() => _full = full);
    } catch (_) {}
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions
  void _toggleFavorite() {
    setState(() => _fav = !_fav);
    widget.onFavorite();
  }

  Future<void> _share() async {
    final car = widget.car;
    final text = 'شوف العربية دي على CARY 🚗\n'
        '${car.title} — ${formatNumber(car.price)} جنيه\n'
        '${CarLinks.build(car.id)}';
    try {
      await Share.share(text, subject: car.title);
    } catch (_) {
      _toast('تعذّرت المشاركة');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _book() async {
    if (widget.bookingBlockedMessage != null) {
      _toast(widget.bookingBlockedMessage!);
      return;
    }
    FocusScope.of(context).unfocus();
    // TODO: اربط بالـ API (إنشاء طلب حجز/شراء)
    await showDialog<void>(
      context: context,
      barrierColor: ThemeController.barrierColor,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                  color: AppColors.tileBg, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.blue, size: 44),
            ),
            const SizedBox(height: 16),
            Text(
              'تم إرسال طلب الحجز بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title),
            ),
            const SizedBox(height: 8),
            Text(
              'هيتم التواصل معاك في أقرب وقت لاستكمال إجراءات الحجز والمعاينة',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14.5, color: AppColors.subtitle, height: 1.6),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('حسناً',
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );

    // بعد الحجز: نضيف السيارة في "حجوزاتي" ونرجع للشاشة الرئيسية على التاب ده
    if (!mounted) return;
    widget.onBook?.call(car, null);
    Navigator.of(context).maybePop();
  }

  void _openImage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullImageScreen(car: car, initialIndex: _page),
      ),
    );
  }

  void _sendOffer() {
    if (widget.bookingBlockedMessage != null) {
      _toast(widget.bookingBlockedMessage!);
      return;
    }
    final text = _offerCtrl.text.replaceAll(',', '').trim();
    if (text.isEmpty) return;

    // التحقق: العرض لازم يكون أقل من سعر السيارة (قاعدة من الـ Domain)
    final offer = int.tryParse(text);
    final error = OfferRules.validate(offer: offer, carPrice: car.price);
    if (error != null) {
      setState(() => _offerError = error);
      return;
    }

    FocusScope.of(context).unfocus();
    // TODO: اربط بالـ API (إرسال عرض السعر)
    _offerCtrl.clear();
    setState(() => _offerError = null);
    _toast('تم إرسال عرضك بنجاح، سيتم الرد عليك قريباً');

    // بعد إرسال العرض: السيارة تتضاف في "حجوزاتي" (مع السعر المقترح) وننقل للتاب ده
    widget.onBook?.call(car, offer);
    Navigator.of(context).maybePop();
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeController.instance.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        // الشريط السفلي (فيه خانة السعر) بيتحرك فوق الكيبورد بنفسه، فالـ Scaffold
        // ميصغّرش الـ body مرتين
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImage(),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 12),
                    _buildSpecsCard(),
                    const SizedBox(height: 12),
                    _buildDescriptionCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildLiftedBottomBar(),
      ),
    );
  }

  /// الشريط السفلي مرفوع فوق الكيبورد: من غير كده خانة "سعر العرض" بتختفي ورا
  /// الكيبورد والمستخدم مبيشوفش الرقم اللي بيكتبه.
  Widget? _buildLiftedBottomBar() {
    final bar = widget.viewOnly
        ? (widget.onEdit == null ? null : _buildEditBar())
        : _buildBottomBar();
    if (bar == null) return null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: bar,
    );
  }

  // ---------------------------------------------------------------- header
  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(14, 8 + topInset, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // يمين: القلب + المشاركة
          if (!widget.viewOnly) ...[
            _HeaderCircle(
              child: Icon(
                _fav ? Icons.favorite : Icons.favorite_border,
                size: 26,
                color: _fav ? AppColors.badge : AppColors.subtitle,
              ),
              onTap: _toggleFavorite,
            ),
            const SizedBox(width: 8),
          ],
          _HeaderCircle(
            child: Icon(Icons.share_outlined,
                size: 26, color: AppColors.subtitle),
            onTap: _share,
          ),
          // النص: فحص معتمد + اسم السيارة
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'فحص CARY المعتمد',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.verified_rounded,
                        color: AppColors.blue, size: 24),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FittedBox: الاسم كامل (مع السنة) بيصغّر نفسه بدل ما يتقطع بنقط
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${car.brand} ${car.model} ${car.year}',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.title,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white, // خلفية اللوجو بيضا حتى في الداكن
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.tone(0xFFE8ECF2)),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: BrandLogo(brandName: car.brand),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // يسار: زرار الرجوع
          _HeaderCircle(
            child: Icon(Icons.arrow_forward_rounded,
                size: 26, color: AppColors.title),
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- image
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الضغط على الصورة بيفتحها بالحجم الكامل (مع تكبير بالإصبعين)
            // معرض الصور: سحب يمين/شمال لعرض كل الصور
            PageView.builder(
              itemCount: car.allImages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openImage,
                child: CarImageView(car: car, path: car.allImages[i]),
              ),
            ),
            // عداد الصور (الضغط عليه بيفتح الصورة كمان)
            Positioned(
              bottom: 14,
              right: 14,
              child: GestureDetector(
                onTap: _openImage,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.62),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '${_page + 1}/${car.images.isNotEmpty ? car.images.length : car.imagesCount} صور',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- info card
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الاسم والمواصفات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.brand} ${car.model}\n${car.year}',
                      style: TextStyle(
                        fontSize: 21,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      car.specsLine,
                      style: TextStyle(
                          fontSize: 14.5, color: AppColors.subtitle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // لوجو الماركة
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white, // خلفية اللوجو بيضا حتى في الداكن
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.tone(0xFFE8ECF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BrandLogo(brandName: car.brand),
                ),
              ),
              const SizedBox(width: 12),
              // السعر
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatNumber(car.price),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'جنيه مصري (كاش أو\nتقسيط)',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 13, height: 1.35, color: AppColors.subtitle),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.fieldBorder, height: 1),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _FeatureChip(
                  icon: Icons.bolt_rounded,
                  text: 'جاهزة للاستلام الفوري',
                  blue: true,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FeatureChip(
                  icon: Icons.assignment_turned_in_outlined,
                  text: 'عقد مسجل فوري',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- specs
  Widget _buildSpecsCard() {
    final tiles = <_SpecData>[
      _SpecData(Icons.calendar_month_outlined, 'سنة الصنع', '${car.year}'),
      _SpecData(
          Icons.speed_rounded, 'العداد الفعلي', '${formatNumber(car.km)} كم'),
      _SpecData(Icons.settings_outlined, 'نوع ناقل الحركة', car.transmission),
      _SpecData(Icons.engineering_outlined, 'سعة المحرك',
          car.engine.isEmpty ? '—' : car.engine),
      _SpecData(Icons.verified_user_outlined, 'وحدة المرور',
          car.trafficUnit.isEmpty ? '—' : car.trafficUnit),
      _SpecData(Icons.badge_outlined, 'رخصة السيارة',
          car.license.isEmpty ? '—' : car.license),
      _SpecData(Icons.palette_outlined, 'اللون الخارجي',
          car.exteriorColor.isEmpty ? '—' : car.exteriorColor),
      _SpecData(Icons.airline_seat_recline_normal_outlined, 'حالة الداخلية',
          car.interiorCondition.isEmpty ? '—' : car.interiorCondition),
      _SpecData(Icons.directions_car_filled_outlined, 'الحالة الخارجية',
          car.exteriorCondition.isEmpty ? '—' : car.exteriorCondition),
      _SpecData(Icons.format_paint_outlined, 'هل تم دهان السيارة؟',
          car.paintStatus.isEmpty ? '—' : car.paintStatus),
      _SpecData(Icons.alt_route_rounded, 'ناقل الحركة',
          car.gearboxCondition.isEmpty ? '—' : car.gearboxCondition),
      _SpecData(Icons.car_repair_outlined, 'العفشة',
          car.suspensionCondition.isEmpty ? '—' : car.suspensionCondition),
      _SpecData(Icons.build_circle_outlined, 'هل يوجد أى مشاكل فى الموتور؟',
          car.engineProblems.isEmpty ? '—' : car.engineProblems),
      _SpecData(Icons.car_crash_outlined, 'هل يوجد بالسيارة أى حوادث؟',
          car.accidentStatus.isEmpty ? '—' : car.accidentStatus),
    ];

    // بناء صفوف من عمودين — آخر خانة فردية بتاخد العرض كله
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final isLastSingle = i + 1 >= tiles.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 10 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _SpecTile(data: tiles[i])),
                if (!isLastSingle) ...[
                  const SizedBox(width: 10),
                  Expanded(child: _SpecTile(data: tiles[i + 1])),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined,
                  color: AppColors.blue, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المواصفات والتفاصيل الأساسية',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tileBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'معتمد\nCARY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.fieldBorder, height: 1),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- description
  Widget _buildDescriptionCard() {
    if (car.description.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الوصف وتقرير الحالة',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
              Icon(Icons.subject_rounded, color: AppColors.blue, size: 30),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.fieldBorder, height: 1),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              car.description,
              style: TextStyle(
                  fontSize: 14.5, height: 1.8, color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- edit bar
  /// زرار تعديل الإعلان (لصاحب الإعلان وهو قيد المراجعة)
  Widget _buildEditBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.fieldBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onEdit!();
              },
              icon: const Icon(Icons.edit_outlined, size: 24),
              label: const Text('تعديل الإعلان',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- bottom bar
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.fieldBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: MediaQuery.of(context).viewInsets.bottom == 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // السعر النهائي + زرار الحجز
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _book,
                        icon: const Icon(
                            Icons.directions_car_filled_outlined,
                            size: 24),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'حجز السيارة / طلب شراء',
                            style: TextStyle(
                                fontSize: 16.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.blue.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'السعر النهائي المعروض',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.subtitle),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${formatNumber(car.price)} ج.م',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // قدم عرض سعرك
              if (car.canNegotiate) ...[
                const SizedBox(height: 14),
                Divider(color: AppColors.fieldBorder, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'قدم عرض سعرك:',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                    Icon(Icons.local_offer_outlined,
                        color: AppColors.blue, size: 24),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // زرار إرسال العرض
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _offerCtrl,
                      builder: (_, v, __) {
                        final enabled =
                            v.text.replaceAll(',', '').trim().isNotEmpty;
                        return SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: enabled ? _sendOffer : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              AppColors.tone(0xFFD7DEE8),
                              disabledForegroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'إرسال العرض',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    // خانة السعر المقترح
                    Expanded(
                      child: Container(
                        height: 52,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _offerError != null
                                  ? AppColors.error
                                  : AppColors.fieldBorder),
                        ),
                        child: Row(
                          children: [
                            Text('ج.م',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.subtitle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _offerCtrl,
                                onChanged: (_) {
                                  if (_offerError != null) {
                                    setState(() => _offerError = null);
                                  }
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [_ThousandsFormatter()],
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                // خط أكبر وغامق عشان الرقم يتقري بسهولة وهو بيتكتب
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.title),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'أدخل السعر المقترح...',
                                  hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.hint),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_offerError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _offerError!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

// =============================================================================
// Widgets مساعدة
// =============================================================================

/// عرض صور السيارة بالحجم الكامل (سحب بين الصور، وتكبير/تصغير بالإصبعين)
class _FullImageScreen extends StatefulWidget {
  final Car car;
  final int initialIndex;
  const _FullImageScreen({required this.car, this.initialIndex = 0});

  @override
  State<_FullImageScreen> createState() => _FullImageScreenState();
}

class _FullImageScreenState extends State<_FullImageScreen> {
  late final PageController _controller =
  PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final images = car.allImages;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: CarImageView(
                      car: car, path: images[i], fit: BoxFit.contain),
                ),
              ),
            ),
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 10,
              start: 14,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              start: 0,
              end: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${car.brand} ${car.model} ${car.year}'
                        '${images.length > 1 ? '  •  ${_index + 1}/${images.length}' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HeaderCircle({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(
          side: BorderSide(color: AppColors.fieldBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Center(child: child)),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool blue;
  const _FeatureChip({required this.icon, required this.text, this.blue = false});

  @override
  Widget build(BuildContext context) {
    final color = blue ? AppColors.blue : AppColors.title;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, color: blue ? AppColors.blue : AppColors.icon, size: 22),
        ],
      ),
    );
  }
}

class _SpecData {
  final IconData icon;
  final String label;
  final String value;
  const _SpecData(this.icon, this.label, this.value);
}

/// خانة مواصفة في شاشة التفاصيل: خلفية فاتحة + أيقونة زرقا + عنوان وقيمة
class _SpecTile extends StatelessWidget {
  final _SpecData data;
  const _SpecTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tileBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.subtitle),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(data.icon, color: AppColors.blue, size: 30),
        ],
      ),
    );
  }
}

/// فواصل الآلاف أثناء الكتابة (نفس فكرة صفحة بيع سيارتك)
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    if (digits.length > 12) digits = digits.substring(0, 12);
    // فاصل كل 3 أرقام: 1250000 -> 1,250,000
    final formatted = digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    // نحافظ على مكان المؤشر (بدل ما يقفز لآخر الرقم لما تعدّل في النص)
    final cursor =
    newValue.selection.baseOffset.clamp(0, newValue.text.length) as int;
    var digitsBefore = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    if (digitsBefore > digits.length) digitsBefore = digits.length;
    var pos = 0, seen = 0;
    while (pos < formatted.length && seen < digitsBefore) {
      if (formatted[pos] != ',') seen++;
      pos++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}