import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';
import '../core/utils/formatters.dart' show formatNumber;
import '../core/widgets/local_image.dart';
import '../features/account/presentation/cubit/account_cubit.dart';
import '../features/cars/presentation/cubit/cars_cubit.dart';
import 'brand_picker_sheet.dart';
import 'car_brand.dart';
import 'my_ad.dart';

/// تاب "بيع سيارتك": فورم إضافة إعلان سيارة.
/// الهيدر (الشعار + السهم) بييجي من الشاشة الرئيسية.
class SellCarTab extends StatefulWidget {
  /// بتتنادى بعد نجاح إرسال الإعلان (الشاشة الرئيسية بتضيفه في "إعلاناتي")
  final ValueChanged<MyAd>? onPublished;

  /// وضع التعديل: لو اتحدد بيتملي الفورم ببيانات الإعلان، وبعد الحفظ بيتنادى
  /// [onPublished] بنسخة معدّلة (نفس الـ id) وترجع "قيد المراجعة"
  final MyAd? editing;

  /// تعديل من إدارة الإعلانات (أدمن/مالك): الحالة وصاحب الإعلان بيفضلوا زي ما هم،
  /// ومش لازم كل الخانات تتملي
  final bool adminEdit;

  const SellCarTab(
      {super.key, this.onPublished, this.editing, this.adminEdit = false});

  @override
  State<SellCarTab> createState() => _SellCarTabState();
}

class _SellCarTabState extends State<SellCarTab> {
  static const _maxPhotos = 10;
  static const _maxDesc = 1000;
  static const _minYear = 1980;

  // ---- الاختيارات (عدّلها زي ما تحب أو اربطها بالـ API)
  static const _fuels = ['بنزين', 'ديزل', 'هايبرد', 'كهرباء', 'غاز طبيعي'];
  static const _transmissions = ['أوتوماتيك', 'مانيوال', 'CVT', 'نصف أوتوماتيك'];
  static const _conditions = ['ممتازة', 'جيدة جدًا', 'جيدة', 'تحتاج صيانة'];
  static const _licenses = [
    'سارية لمدة سنة',
    'سارية لمدة سنتين',
    'سارية لمدة 3 سنوات',
    'منتهية',
  ];
  static const _interiors = ['ممتازة', 'جيدة', 'متوسطة', 'تحتاج تجديد'];
  static const _exteriors = ['بحالة الزيرو', 'ممتازة', 'جيدة', 'تحتاج إصلاح'];
  static const _paints = ['فبريكا (لون المصنع)', 'دهان جزئي', 'دهان كامل'];
  static const _gearboxConditions = ['ممتازة', 'جيدة', 'مقبول'];
  static const _suspensionConditions = ['ممتازة', 'جيدة', 'مقبول'];
  static const _engineProblemOptions = ['نعم', 'لا'];
  static const _accidents = ['بدون حوادث او خبطات', 'خبطة بسيطة', 'حادث كبير'];
  static const _bodyTypes = <String, IconData>{
    'سيدان': Icons.directions_car_filled_outlined,
    'SUV': Icons.airport_shuttle_outlined,
    'هاتشباك': Icons.time_to_leave_outlined,
    'كروس أوفر': Icons.directions_car_outlined,
    'كوبيه': Icons.drive_eta_outlined,
    'بيك أب': Icons.local_shipping_outlined,
  };

  // ---- الحالة
  final _picker = ImagePicker();
  final _model = TextEditingController();
  final _km = TextEditingController();
  final _color = TextEditingController();
  final _cc = TextEditingController();
  final _traffic = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();

  CarBrand? _brand;
  int? _year;
  String? _fuel;
  String? _transmission;
  String? _condition;
  String? _interior;
  String? _exterior;
  String? _license;
  String? _paint;
  String? _gearbox;
  String? _suspension;
  String? _engineProblem;
  String? _accident;
  String _body = 'سيدان';
  bool _negotiable = false;
  bool _submitted = false;
  bool _loading = false;
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    final ad = widget.editing;
    if (ad != null) _prefill(ad);
  }

  /// ملء الفورم ببيانات إعلان موجود (وضع التعديل)
  void _prefill(MyAd ad) {
    String? opt(String k, List<String> options) {
      final v = ad.details[k];
      return v != null && options.contains(v) ? v : null;
    }

    _model.text = ad.model;
    _year = ad.year;
    _km.text = '${ad.km}';
    _price.text = formatNumber(ad.price);
    _traffic.text = ad.location;
    _color.text = ad.details['اللون'] ?? '';
    _cc.text = ad.details['سعة المحرك'] ?? '';
    _desc.text = ad.details['الوصف'] ?? '';
    _fuel = opt('نوع المحرك', _fuels);
    _transmission =
        _transmissions.contains(ad.transmission) ? ad.transmission : null;
    _condition = opt('الحالة', _conditions);
    _license = opt('الرخصة', _licenses);
    _interior = opt('الداخلية', _interiors);
    _exterior = opt('الخارجية', _exteriors);
    _paint = opt('الدهان', _paints);
    _gearbox = opt('الجير', _gearboxConditions);
    _suspension = opt('المساعدين', _suspensionConditions);
    _engineProblem = opt('مشاكل المحرك', _engineProblemOptions);
    _accident = opt('الحوادث', _accidents);
    final body = ad.details['شكل السيارة'];
    if (body != null && _bodyTypes.containsKey(body)) _body = body;
    _negotiable = ad.details['قابل للتفاوض'] == 'نعم';
    _images.addAll(ad.allImages.map(XFile.new));
    CarBrand.findFor(ad.brandName).then((b) {
      if (mounted && b != null) setState(() => _brand = b);
    });
  }

  @override
  void dispose() {
    for (final c in [_model, _km, _color, _cc, _traffic, _desc, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _bad(bool invalid) => _submitted && invalid;

  // ---------------------------------------------------------------- actions
  Future<void> _pickBrand() async {
    FocusScope.of(context).unfocus();
    final b = await showBrandPickerSheet(
      context,
      selected: _brand,
      brandCounts: context.read<CarsCubit>().state.brandCounts,
    );
    if (b != null && mounted) setState(() => _brand = b);
  }

  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final years = [for (var y = now; y >= _minYear; y--) '$y'];
    final r = await _pickOption('سنة الصنع', years, _year?.toString());
    if (r != null) setState(() => _year = int.parse(r));
  }

  Future<String?> _pickOption(
      String title, List<String> options, String? selected) {
    FocusScope.of(context).unfocus();
    return showModalBottomSheet<String>(
      context: context,
      barrierColor: ThemeController.barrierColor,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.tone(0xFFDDE3EC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final o = options[i];
                  final sel = o == selected;
                  return ListTile(
                    onTap: () => Navigator.of(ctx).pop(o),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    tileColor: sel ? AppColors.tileBg : null,
                    title: Text(
                      o,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                        color: sel ? AppColors.blue : AppColors.title,
                      ),
                    ),
                    trailing: sel
                        ? Icon(Icons.check_circle,
                        color: AppColors.blue)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - _images.length;
    if (remaining <= 0) {
      _toast('أقصى عدد للصور $_maxPhotos');
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() => _images.addAll(picked.take(remaining)));
      if (picked.length > remaining) _toast('أقصى عدد للصور $_maxPhotos');
    } catch (_) {
      _toast('تعذّر اختيار الصور');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);

    final missing = widget.adminEdit
        ? (_brand == null ||
            _model.text.trim().isEmpty ||
            _year == null ||
            _km.text.isEmpty ||
            _price.text.isEmpty ||
            _images.isEmpty)
        : _brand == null ||
        _model.text.trim().isEmpty ||
        _year == null ||
        _fuel == null ||
        _transmission == null ||
        _km.text.isEmpty ||
        _color.text.trim().isEmpty ||
        _cc.text.isEmpty ||
        _condition == null ||
        _license == null ||
        _interior == null ||
        _exterior == null ||
        _paint == null ||
        _gearbox == null ||
        _suspension == null ||
        _engineProblem == null ||
        _accident == null ||
        _traffic.text.trim().isEmpty ||
        _price.text.isEmpty ||
        _images.isEmpty;
    if (missing) {
      _toast('من فضلك أكمل كل البيانات وأضف صورة واحدة على الأقل');
      return;
    }

    setState(() => _loading = true);
    try {
      // TODO: اربط بالـ API وابعت:
      // brand: _brand!.id / nameEn, model, year, fuel, transmission, km,
      // color, cc (نص حر: أرقام ونصوص), condition, license, traffic,
      // interior, exterior, body,
      // paint (_paint), gearbox (_gearbox), suspension (_suspension),
      // engineProblem (_engineProblem), accident (_accident),
      // description (اختياري), negotiable,
      // price: _price.text.replaceAll(',', '') (من غير فواصل),
      // images (الأولى هي الرئيسية)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      final owner = context.read<AccountCubit>().state.profile;
      final ad = MyAd(
        id: widget.editing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        brandName: _brand!.nameAr,
        brandLogoUrl: _brand!.logoUrl,
        model: _model.text.trim(),
        year: _year!,
        km: int.tryParse(_km.text) ?? 0,
        transmission: _transmission ?? widget.editing?.transmission ?? '',
        location: _traffic.text.trim(),
        price: int.tryParse(_price.text.replaceAll(',', '')) ?? 0,
        imagePath: _images.first.path,
        images: [for (final i in _images) i.path],
        createdAt: widget.editing?.createdAt ?? DateTime.now(),
        approvedAt: widget.adminEdit ? widget.editing!.approvedAt : null,
        // تعديل: صاحب الإعلان الأصلي بيفضل (حتى لو اللي عدّل أدمن)
        ownerName: widget.editing?.ownerName ?? owner?.fullName ?? '',
        ownerPhone: widget.editing?.ownerPhone ?? owner?.phone ?? '',
        ownerEmail: widget.editing?.ownerEmail ?? owner?.email ?? '',
        status: widget.adminEdit
            ? widget.editing!.status
            : MyAdStatus.pending,
        rejectionReason:
            widget.adminEdit ? widget.editing!.rejectionReason : null,
        details: {
          'نوع المحرك': _fuel ?? '',
          'ناقل الحركة': _transmission ?? '',
          'الحالة': _condition ?? '',
          'اللون': _color.text.trim(),
          'سعة المحرك': _cc.text.trim(),
          'الرخصة': _license ?? '',
          'وحدة المرور': _traffic.text.trim(),
          'الداخلية': _interior ?? '',
          'الخارجية': _exterior ?? '',
          'الدهان': _paint ?? '',
          'الجير': _gearbox ?? '',
          'المساعدين': _suspension ?? '',
          'مشاكل المحرك': _engineProblem ?? '',
          'الحوادث': _accident ?? '',
          'شكل السيارة': _body,
          'قابل للتفاوض': _negotiable ? 'نعم' : 'لا',
          if (_desc.text.trim().isNotEmpty) 'الوصف': _desc.text.trim(),
        },
      );
      final editing = widget.editing != null;
      if (!editing) _reset();
      widget.onPublished?.call(ad);
      _toast(editing
          ? (widget.adminEdit
              ? 'تم حفظ التعديلات'
              : 'تم حفظ التعديلات وإعادة الإعلان للمراجعة')
          : 'تم إرسال الإعلان للمراجعة بنجاح');
    } catch (_) {
      if (!mounted) return;
      _toast('تعذّر إرسال الإعلان، جرّب تاني');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    for (final c in [_model, _km, _color, _cc, _traffic, _desc, _price]) {
      c.clear();
    }
    setState(() {
      _brand = null;
      _year = null;
      _fuel = _transmission = _condition = _interior = _exterior = null;
      _license = null;
      _paint = _gearbox = _suspension = _engineProblem = _accident = null;
      _body = 'سيدان';
      _negotiable = false;
      _submitted = false;
      _images.clear();
    });
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 18),

          // ------------------------------------------------ البيانات الأساسية
          _SectionCard(
            icon: Icons.description_outlined,
            title: 'البيانات الأساسية',
            child: Column(
              children: [
                _row(
                  _pick(
                    icon: Icons.directions_car_filled_outlined,
                    label: 'الماركة',
                    value: _brand?.nameAr,
                    hint: 'اختر الماركة',
                    onTap: _pickBrand,
                    bad: _bad(_brand == null),
                  ),
                  _input(
                    icon: Icons.history_toggle_off_rounded,
                    label: 'الموديل',
                    controller: _model,
                    hint: 'مثال: كورولا',
                    bad: _bad(_model.text.trim().isEmpty),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  _pick(
                    icon: Icons.calendar_month_outlined,
                    label: 'سنة الصنع',
                    value: _year?.toString(),
                    hint: 'اختر السنة ($_minYear - $nowYear)',
                    onTap: _pickYear,
                    bad: _bad(_year == null),
                  ),
                  _pick(
                    icon: Icons.settings_outlined,
                    label: 'نوع المحرك',
                    value: _fuel,
                    hint: 'اختر نوع المحرك',
                    onTap: () async {
                      final r = await _pickOption('نوع المحرك', _fuels, _fuel);
                      if (r != null) setState(() => _fuel = r);
                    },
                    bad: _bad(_fuel == null),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  _input(
                    icon: Icons.speed_rounded,
                    label: 'عدد الكيلومترات',
                    controller: _km,
                    hint: 'مثال: 45000',
                    numeric: true,
                    trailingText: 'كم',
                    bad: _bad(_km.text.isEmpty),
                  ),
                  _pick(
                    icon: Icons.alt_route_rounded,
                    label: 'نوع ناقل الحركة',
                    value: _transmission,
                    hint: 'اختر نوع الجير',
                    onTap: () async {
                      final r = await _pickOption(
                          'نوع ناقل الحركة', _transmissions, _transmission);
                      if (r != null) setState(() => _transmission = r);
                    },
                    bad: _bad(_transmission == null),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  _input(
                    icon: Icons.palette_outlined,
                    label: 'لون السيارة',
                    controller: _color,
                    hint: 'مثال: كحلي، أسود',
                    bad: _bad(_color.text.trim().isEmpty),
                  ),
                  _input(
                    icon: Icons.engineering_outlined,
                    label: 'سعة المحرك',
                    controller: _cc,
                    // نص حر (أرقام ونصوص) عشان يختلف من عربية للتانية:
                    // "1600 CC تيربو"، "1.6L"، "كهرباء"...
                    hint: 'مثال: 1600 CC تيربو',
                    bad: _bad(_cc.text.trim().isEmpty),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------ المواصفات الفنية
          _SectionCard(
            icon: Icons.tune_rounded,
            title: 'المواصفات الفنية',
            child: Column(
              children: [
                _row(
                  _pick(
                    icon: Icons.verified_outlined,
                    label: 'حالة السيارة',
                    value: _condition,
                    hint: 'اختر حالة السيارة',
                    onTap: () async {
                      final r = await _pickOption(
                          'حالة السيارة', _conditions, _condition);
                      if (r != null) setState(() => _condition = r);
                    },
                    bad: _bad(_condition == null),
                  ),
                  _input(
                    icon: Icons.local_police_outlined,
                    label: 'وحدة المرور',
                    controller: _traffic,
                    hint: 'مثال: مرور أسيوط',
                    bad: _bad(_traffic.text.trim().isEmpty),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  _pick(
                    icon: Icons.badge_outlined,
                    label: 'سريان الرخصة',
                    value: _license,
                    hint: 'اختر مدة السريان',
                    bad: _bad(_license == null),
                    onTap: () async {
                      final r = await _pickOption(
                          'سريان رخصة السيارة', _licenses, _license);
                      if (r != null) setState(() => _license = r);
                    },
                  ),
                  _pick(
                    icon: Icons.airline_seat_recline_normal_outlined,
                    label: 'حالة الداخلية',
                    value: _interior,
                    hint: 'اختر الحالة الداخلية',
                    onTap: () async {
                      final r = await _pickOption(
                          'حالة الداخلية', _interiors, _interior);
                      if (r != null) setState(() => _interior = r);
                    },
                    bad: _bad(_interior == null),
                  ),
                ),
                const SizedBox(height: 10),
                _pick(
                  icon: Icons.directions_car_filled_outlined,
                  label: 'الحالة الخارجية',
                  value: _exterior,
                  hint: 'اختر الحالة الخارجية',
                  onTap: () async {
                    final r = await _pickOption(
                        'الحالة الخارجية', _exteriors, _exterior);
                    if (r != null) setState(() => _exterior = r);
                  },
                  bad: _bad(_exterior == null),
                ),
                const SizedBox(height: 10),
                _pick(
                  icon: Icons.format_paint_outlined,
                  label: 'هل تم دهان السيارة؟',
                  value: _paint,
                  hint: 'اختر حالة الدهان',
                  onTap: () async {
                    final r = await _pickOption(
                        'هل تم دهان السيارة؟', _paints, _paint);
                    if (r != null) setState(() => _paint = r);
                  },
                  bad: _bad(_paint == null),
                ),
                const SizedBox(height: 10),
                _row(
                  _pick(
                    icon: Icons.alt_route_rounded,
                    label: 'ناقل الحركة',
                    value: _gearbox,
                    hint: 'اختر الحالة',
                    onTap: () async {
                      final r = await _pickOption(
                          'ناقل الحركة', _gearboxConditions, _gearbox);
                      if (r != null) setState(() => _gearbox = r);
                    },
                    bad: _bad(_gearbox == null),
                  ),
                  _pick(
                    icon: Icons.car_repair_outlined,
                    label: 'العفشة',
                    value: _suspension,
                    hint: 'اختر الحالة',
                    onTap: () async {
                      final r = await _pickOption(
                          'العفشة', _suspensionConditions, _suspension);
                      if (r != null) setState(() => _suspension = r);
                    },
                    bad: _bad(_suspension == null),
                  ),
                ),
                const SizedBox(height: 10),
                _pick(
                  icon: Icons.build_circle_outlined,
                  label: 'هل يوجد أى مشاكل فى الموتور؟',
                  value: _engineProblem,
                  hint: 'اختر',
                  onTap: () async {
                    final r = await _pickOption('هل يوجد أى مشاكل فى الموتور؟',
                        _engineProblemOptions, _engineProblem);
                    if (r != null) setState(() => _engineProblem = r);
                  },
                  bad: _bad(_engineProblem == null),
                ),
                const SizedBox(height: 10),
                _pick(
                  icon: Icons.car_crash_outlined,
                  label: 'هل يوجد بالسيارة أى حوادث؟',
                  value: _accident,
                  hint: 'اختر حالة الحوادث',
                  onTap: () async {
                    final r = await _pickOption('هل يوجد بالسيارة أى حوادث؟',
                        _accidents, _accident);
                    if (r != null) setState(() => _accident = r);
                  },
                  bad: _bad(_accident == null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------ الشكل الخارجي
          _SectionCard(
            icon: Icons.directions_car_filled_outlined,
            title: 'الشكل الخارجي',
            trailing: _Chip(_body),
            child: SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _bodyTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final e = _bodyTypes.entries.elementAt(i);
                  return _BodyTypeCard(
                    label: e.key,
                    icon: e.value,
                    selected: e.key == _body,
                    onTap: () => setState(() => _body = e.key),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------ الوصف
          _SectionCard(
            icon: Icons.edit_note_rounded,
            title: 'وصف تفصيلي عن السيارة',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: TextField(
                    controller: _desc,
                    minLines: 2,
                    maxLines: 4,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxDesc),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        fontSize: 15, color: AppColors.title, height: 1.5),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                      'اكتب وصفاً مفصلاً عن السيارة (المميزات، الحالة، أي ملاحظات إضافية...)',
                      hintStyle: TextStyle(
                          fontSize: 14.5, color: AppColors.hint, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_desc.text.length}/$_maxDesc حرف',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.subtitle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------ تفاوض + سعر
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildNegotiable()),
                const SizedBox(width: 12),
                Expanded(child: _buildPrice()),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------ الصور + إرسال
          _buildPhotos(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.editing != null ? 'تعديل الإعلان' : 'بيع سيارتك',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.directions_car_filled_outlined,
                  color: AppColors.blue, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أضف بيانات سيارتك لعرضها على المنصة',
          style: TextStyle(fontSize: 15, color: AppColors.subtitle),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 68,
            height: 3.5,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- helpers
  Widget _row(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    ),
  );

  Widget _pick({
    required IconData icon,
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    bool bad = false,
    Color? valueColor,
    bool boldValue = false,
  }) {
    final has = value != null;
    return _Tile(
      icon: icon,
      label: label,
      error: bad,
      onTap: onTap,
      trailing: Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.icon, size: 26),
      child: Text(
        has ? value : hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: (has && boldValue) ? FontWeight.w800 : FontWeight.w500,
          color: has ? (valueColor ?? AppColors.title) : AppColors.hint,
        ),
      ),
    );
  }

  Widget _input({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    bool numeric = false,
    bool bad = false,
    String? trailingText,
    String? badge,
  }) {
    // النص الإرشادي بيتعرض كـ Text عادي بسطر واحد وبنقط في الآخر (ellipsis)،
    // عشان ميحصلش overflow مهما كان طوله.
    final field = Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isEmpty
              ? IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                hint,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontSize: 13, color: AppColors.hint),
              ),
            ),
          )
              : const SizedBox.shrink(),
        ),
        TextField(
          controller: controller,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: numeric ? [_DigitsOnly()] : null,
          textAlign: numeric ? TextAlign.right : TextAlign.start,
          textDirection: numeric ? TextDirection.ltr : null,
          onChanged: (_) {
            if (_submitted) setState(() {});
          },
          maxLines: 1,
          style: TextStyle(fontSize: 14, color: AppColors.title),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    return _Tile(
      icon: icon,
      label: label,
      error: bad,
      trailing: trailingText != null
          ? Text(trailingText,
          style:
          TextStyle(fontSize: 13, color: AppColors.subtitle))
          : null,
      child: badge == null
          ? field
          : Row(
        children: [
          Expanded(child: field),
          const SizedBox(width: 6),
          _Chip(badge, green: true),
        ],
      ),
    );
  }

  Widget _buildNegotiable() {
    Widget seg(String text, bool value) {
      final sel = _negotiable == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _negotiable = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? AppColors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : AppColors.title,
              ),
            ),
          ),
        ),
      );
    }

    return _MiniCard(
      icon: Icons.handshake_outlined,
      title: 'قابل للتفاوض؟',
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.tileBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [seg('نعم', true), seg('لا', false)]),
      ),
    );
  }

  Widget _buildPrice() {
    final bad = _bad(_price.text.isEmpty);
    return _MiniCard(
      icon: Icons.payments_outlined,
      title: 'السعر المطلوب',
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
              color: bad ? AppColors.error : AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Text('ج.م',
                style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
            const SizedBox(width: 6),
            Expanded(
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _price,
                    builder: (_, v, __) => v.text.isEmpty
                        ? IgnorePointer(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'أدخل السعر',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.hint,
                          ),
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsFormatter()],
                    onChanged: (_) {
                      if (_submitted) setState(() {});
                    },
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotos() {
    final noPhotos = _bad(_images.isEmpty);
    return _SectionCard(
      icon: Icons.photo_camera_outlined,
      title: 'الصور',
      trailing: Text(
        '${_images.length} من $_maxPhotos صور',
        style: TextStyle(fontSize: 14, color: AppColors.subtitle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _addPhotos,
            child: CustomPaint(
              painter: _DashedRRectPainter(
                color: noPhotos ? AppColors.error : AppColors.tone(0xFF9CC3F0),
                radius: 18,
              ),
              child: Container(
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.tone(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: AppColors.blue, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'إضافة صور السيارة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '(يمكنك رفع عدد صور حتى $_maxPhotos صور)',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.subtitle),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _images.length; i++) _thumb(i),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.blue.withOpacity(0.85),
                disabledForegroundColor: Colors.white70,
                elevation: 4,
                shadowColor: AppColors.blue.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.6, color: Colors.white),
                )
                    : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send_outlined, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      widget.editing != null ? 'حفظ التعديلات' : 'إرسال الإعلان',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// أول صورة هي "الرئيسية"، والضغط على أي صورة بيخليها الرئيسية
  Widget _thumb(int i) {
    final isMain = i == 0;
    return GestureDetector(
      onTap: () {
        if (isMain) return;
        setState(() => _images.insert(0, _images.removeAt(i)));
      },
      child: SizedBox(
        width: 100,
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LocalImage(
                path: _images[i].path,
                fallback: Container(
                  color: AppColors.tone(0xFFE5EAF2),
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.icon),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(i)),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              if (isMain)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.blue,
                    alignment: Alignment.center,
                    child: const Text(
                      'الرئيسية',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700),
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

// =============================================================================
// Widgets مساعدة
// =============================================================================

/// كارت قسم أبيض بعنوان وأيقونة
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// كارت صغير (للتفاوض والسعر)
class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _MiniCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 24),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// خانة حقل (أيقونة + عنوان + محتوى)
class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;
  final bool error;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.error = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: error ? AppColors.error : AppColors.fieldBorder,
              width: error ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.blue, size: 24),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool green;
  const _Chip(this.text, {this.green = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: green ? AppColors.tone(0xFFDCFCE7) : AppColors.tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: green ? AppColors.tone(0xFF166534) : AppColors.blue,
        ),
      ),
    );
  }
}

class _BodyTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BodyTypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.subtitle;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        decoration: BoxDecoration(
          color: selected ? AppColors.tileBg : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.tone(0xFFDDE5EF),
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Stack(
          children: [
            // الدايرة (radio) في الركن
            PositionedDirectional(
              top: 7,
              start: 7,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.blue : AppColors.tone(0xFFC3CCD9),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    : null,
              ),
            ),
            // الأيقونة والاسم: بتصغّر نفسها لو المساحة ضاقت، فمفيش overflow
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 22, 6, 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 24, color: color),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? AppColors.blue : AppColors.title,
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
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// أرقام بس، ويحوّل الأرقام العربية لإنجليزية
class _DigitsOnly extends TextInputFormatter {
  static const _arabic = '٠١٢٣٤٥٦٧٨٩';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    for (var i = 0; i < _arabic.length; i++) {
      text = text.replaceAll(_arabic[i], '$i');
    }
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// أرقام بس، وبيحط فاصلة كل 3 أرقام (1,250,000)، ويحوّل الأرقام العربية لإنجليزية
class _ThousandsFormatter extends TextInputFormatter {
  static const _arabic = '٠١٢٣٤٥٦٧٨٩';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = newValue.text;
    for (var i = 0; i < _arabic.length; i++) {
      raw = raw.replaceAll(_arabic[i], '$i');
    }

    // عدد الأرقام قبل المؤشر (من غير الفواصل) عشان نرجّعه لمكانه بعد التنسيق
    final cursor = newValue.selection.baseOffset.clamp(0, raw.length);
    final digitsBeforeCursor =
        RegExp(r'[0-9]').allMatches(raw.substring(0, cursor)).length;

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final buf = StringBuffer();
    var newCursor = 0;
    var seen = 0;
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
      seen++;
      if (seen == digitsBeforeCursor) newCursor = buf.length;
    }
    if (digitsBeforeCursor == 0) newCursor = 0;

    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
}