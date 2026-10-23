// Presentation: شاشة "إدارة الحجوزات" (للأدمن والمالك).
// شريط علوي: الحجوزات النشطة / العمليات الناجحة / العمليات الفاشلة.
// تحت كل تاب قايمة السيارات، وتحت كل سيارة زرار "تفاصيل الحجز".
// تفاصيل الحجز: تفاصيل السيارة + بيانات البائع والمشتري (+ السعر المعروض والمطلوب لو فيه تفاوض).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/formatters.dart' show formatNumber;
import '../../../../core/widgets/admin_search_field.dart';
import '../../../../core/widgets/date_info_row.dart';
import '../../../../screens/bookings_store.dart';
import '../../../cars/domain/entities/car.dart';
import '../../../cars/presentation/widgets/car_card.dart' show CarImageView;

extension _StatusUi on ManagedBookingStatus {
  String get title => switch (this) {
        ManagedBookingStatus.active => 'الحجوزات النشطة',
        ManagedBookingStatus.success => 'العمليات الناجحة',
        ManagedBookingStatus.failed => 'العمليات الفاشلة',
      };

  String get empty => switch (this) {
        ManagedBookingStatus.active => 'مفيش حجوزات نشطة',
        ManagedBookingStatus.success => 'مفيش عمليات ناجحة',
        ManagedBookingStatus.failed => 'مفيش عمليات فاشلة',
      };

  IconData get icon => switch (this) {
        ManagedBookingStatus.active => Icons.pending_actions_rounded,
        ManagedBookingStatus.success => Icons.check_circle_outline_rounded,
        ManagedBookingStatus.failed => Icons.cancel_outlined,
      };

  Color get color => switch (this) {
        ManagedBookingStatus.active => AppColors.blue,
        ManagedBookingStatus.success => AppColors.tone(0xFF0E9F6E),
        ManagedBookingStatus.failed => AppColors.error,
      };
}

AppBar _appBar(String title) => AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.title),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.title,
        ),
      ),
    );

// =============================================================================
// شريط علوي بـ 3 تابات (زي إدارة الإعلانات) + قايمة السيارات تحت كل تاب
// =============================================================================

class BookingsManagementPage extends StatefulWidget {
  const BookingsManagementPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BookingsManagementPage()),
      );

  @override
  State<BookingsManagementPage> createState() => _BookingsManagementPageState();
}

class _BookingsManagementPageState extends State<BookingsManagementPage> {
  String _query = '';

  /// البحث: رقم الهاتف / الاسم / الجيميل (مشتري أو بائع) / اسم السيارة
  bool _match(ManagedBooking b) => matchesQuery(_query, [
        b.buyerPhone,
        b.buyerName,
        b.buyerEmail,
        b.sellerPhone,
        b.sellerName,
        b.sellerEmail,
        b.car.title,
        b.car.brand,
        b.car.model,
      ]);

  @override
  Widget build(BuildContext context) {
    final store = BookingsAdminStore.instance;
    const statuses = ManagedBookingStatus.values;
    return DefaultTabController(
      length: statuses.length,
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.title),
          title: Text(
            'إدارة الحجوزات',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.blue,
                unselectedLabelColor: AppColors.subtitle,
                indicatorColor: AppColors.blue,
                labelStyle: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800),
                tabs: [
                  for (final s in statuses)
                    Tab(
                        text:
                            '${s.title} (${store.byStatus(s).where(_match).length})'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            AdminSearchField(
              hint: 'ابحث بالاسم أو رقم الهاتف أو الجيميل أو اسم السيارة...',
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final s in statuses)
                    _BookingsList(
                        status: s,
                        filter: _match,
                        searching: _query.trim().isNotEmpty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final ManagedBookingStatus status;
  final bool Function(ManagedBooking) filter;
  final bool searching;
  const _BookingsList(
      {required this.status, required this.filter, this.searching = false});

  @override
  Widget build(BuildContext context) {
    final store = BookingsAdminStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.byStatus(status).where(filter).toList();
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.icon),
                const SizedBox(height: 12),
                Text(
                  searching ? 'مفيش نتائج مطابقة للبحث' : status.empty,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _BookingCard(booking: items[i]),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ManagedBooking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final car = booking.car;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: booking.status.color.withOpacity(0.4)),
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
          AspectRatio(aspectRatio: 1.9, child: CarImageView(car: car)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  car.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatNumber(car.price)} ج.م',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
                // تاريخ ووقت طلب الحجز + تاريخ ووقت نجاح/فشل العملية
                DateInfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'طلب الحجز',
                  value: formatDateTime(booking.createdAt),
                ),
                if (booking.completedAt != null &&
                    booking.status == ManagedBookingStatus.success)
                  DateInfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'نجاح العملية',
                    value: formatDateTime(booking.completedAt!),
                    color: AppColors.tone(0xFF16A34A),
                  ),
                if (booking.completedAt != null &&
                    booking.status == ManagedBookingStatus.failed)
                  DateInfoRow(
                    icon: Icons.cancel_outlined,
                    label: 'فشل العملية',
                    value: formatDateTime(booking.completedAt!),
                    color: AppColors.error,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            BookingDetailsPage(bookingId: booking.id),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 22),
                    label: const Text('تفاصيل الحجز',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// الخطوة 3: تفاصيل الحجز
// =============================================================================

class BookingDetailsPage extends StatelessWidget {
  final String bookingId;
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final store = BookingsAdminStore.instance;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _appBar('تفاصيل الحجز'),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          ManagedBooking? b;
          for (final s in ManagedBookingStatus.values) {
            for (final x in store.byStatus(s)) {
              if (x.id == bookingId) b = x;
            }
          }
          if (b == null) return const SizedBox.shrink();
          return _body(context, b);
        },
      ),
    );
  }

  Widget _body(BuildContext context, ManagedBooking b) {
    final car = b.car;
    final rows = <(String, String)>[
      ('السيارة', car.title),
      ('سنة الصنع', '${car.year}'),
      ('ناقل الحركة', car.transmission),
      ('العداد', '${formatNumber(car.km)} كم'),
      if (car.bodyType.isNotEmpty) ('شكل السيارة', car.bodyType),
      if (car.drive.isNotEmpty) ('الدفع', car.drive),
      if (car.engine.isNotEmpty) ('سعة المحرك', car.engine),
      if (car.horsepower.isNotEmpty) ('القوة', car.horsepower),
      if (car.trafficUnit.isNotEmpty) ('وحدة المرور', car.trafficUnit),
      if (car.license.isNotEmpty) ('الرخصة', car.license),
      if (car.exteriorColor.isNotEmpty) ('اللون', car.exteriorColor),
      if (car.interiorCondition.isNotEmpty)
        ('الداخلية', car.interiorCondition),
      if (car.exteriorCondition.isNotEmpty)
        ('الخارجية', car.exteriorCondition),
      if (car.paintStatus.isNotEmpty) ('الدهان', car.paintStatus),
      if (car.gearboxCondition.isNotEmpty) ('الجير', car.gearboxCondition),
      if (car.suspensionCondition.isNotEmpty)
        ('المساعدين', car.suspensionCondition),
      if (car.engineProblems.isNotEmpty)
        ('مشاكل المحرك', car.engineProblems),
      if (car.accidentStatus.isNotEmpty) ('الحوادث', car.accidentStatus),
      if (car.description.isNotEmpty) ('الوصف', car.description),
    ];

    // السعر المعروض والمطلوب: بس لو السيارة قابلة للتفاوض
    final showNegotiation = car.negotiable || b.offerPrice != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // حالة الحجز
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: b.status.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(b.status.icon, color: b.status.color),
              const SizedBox(width: 8),
              Text(b.status.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: b.status.color,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _Section(
          title: 'تفاصيل السيارة',
          icon: Icons.directions_car_filled_outlined,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.8,
                child: CarImageView(car: car),
              ),
            ),
            const SizedBox(height: 10),
            for (final r in rows) _kv(r.$1, r.$2),
          ],
        ),
        const SizedBox(height: 14),

        _Section(
          title: 'الأسعار',
          icon: Icons.payments_outlined,
          children: [
            _kv('السعر المعروض', '${formatNumber(car.price)} ج.م',
                highlight: true),
            if (showNegotiation)
              _kv(
                'السعر المطلوب',
                b.offerPrice == null
                    ? 'لم يُقدَّم عرض'
                    : '${formatNumber(b.offerPrice!)} ج.م',
                highlight: b.offerPrice != null,
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (b.status == ManagedBookingStatus.success &&
            b.buyerPaid != null) ...[
          _Section(
            title: 'تفاصيل العملية',
            icon: Icons.receipt_long_outlined,
            children: [
              _kv('دفعه المشتري', '${formatNumber(b.buyerPaid!)} ج.م'),
              _kv('استلمه البائع', '${formatNumber(b.sellerReceived ?? 0)} ج.م'),
              _kv('العمولة', '${formatNumber(b.commission ?? 0)} ج.م',
                  highlight: true),
            ],
          ),
          const SizedBox(height: 14),
        ],

        _Section(
          title: 'بيانات البائع',
          icon: Icons.storefront_outlined,
          children: [
            _Party(
                name: b.sellerName, phone: b.sellerPhone, email: b.sellerEmail),
          ],
        ),
        const SizedBox(height: 14),

        _Section(
          title: 'بيانات المشتري',
          icon: Icons.person_outline_rounded,
          children: [
            _Party(
                name: b.buyerName, phone: b.buyerPhone, email: b.buyerEmail),
          ],
        ),

        // إنهاء الحجز النشط
        if (b.status == ManagedBookingStatus.active) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  'نجحت العملية',
                  Icons.check_circle_outline_rounded,
                  AppColors.tone(0xFF0E9F6E),
                  () => _completeDeal(context, b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'فشلت العملية',
                  Icons.close_rounded,
                  AppColors.error,
                  () => BookingsAdminStore.instance
                      .setStatus(b.id, ManagedBookingStatus.failed),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// نجحت العملية: صفحة إدخال المبالغ، وبعد التأكيد بيتسجّل البيع
  Future<void> _completeDeal(BuildContext context, ManagedBooking b) async {
    final r = await Navigator.of(context).push<_DealAmounts>(
      MaterialPageRoute<_DealAmounts>(
        builder: (_) => _CompleteDealPage(booking: b),
      ),
    );
    if (r == null) return;
    BookingsAdminStore.instance.completeSuccess(
      b.id,
      buyerPaid: r.buyerPaid,
      sellerReceived: r.sellerReceived,
      commission: r.commission,
    );
  }

  Widget _actionBtn(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text,
              style:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static Widget _kv(String k, String v, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(k,
                  style: TextStyle(fontSize: 13.5, color: AppColors.subtitle)),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  fontSize: highlight ? 16.5 : 14,
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.blue : AppColors.title,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 24),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.fieldBorder, height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// الاسم / الرقم / الجيميل (بالضغط ينسخ)
class _Party extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  const _Party(
      {required this.name, required this.phone, required this.email});

  Widget _row(BuildContext context, IconData icon, String label, String v) {
    final canCopy = v.trim().isNotEmpty;
    return InkWell(
      onTap: !canCopy
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: v.trim()));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text('تم نسخ $label'),
                  behavior: SnackBarBehavior.floating,
                ));
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.blue),
            const SizedBox(width: 8),
            Text('$label: ',
                style: TextStyle(fontSize: 13.5, color: AppColors.subtitle)),
            Expanded(
              child: Text(
                canCopy ? v.trim() : 'غير متوفر',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
            ),
            if (canCopy)
              Icon(Icons.copy_rounded, size: 16, color: AppColors.icon),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _row(context, Icons.person_outline_rounded, 'الاسم', name),
          _row(context, Icons.phone_outlined, 'الرقم', phone),
          _row(context, Icons.email_outlined, 'الجيميل', email),
        ],
      );
}

// =============================================================================
// صفحة إدخال مبالغ العملية الناجحة
// =============================================================================

class _DealAmounts {
  final int buyerPaid;
  final int sellerReceived;
  final int commission;
  const _DealAmounts(this.buyerPaid, this.sellerReceived, this.commission);
}

class _CompleteDealPage extends StatefulWidget {
  final ManagedBooking booking;
  const _CompleteDealPage({required this.booking});

  @override
  State<_CompleteDealPage> createState() => _CompleteDealPageState();
}

class _CompleteDealPageState extends State<_CompleteDealPage> {
  late final _buyerPaid = TextEditingController(
      text: '${widget.booking.offerPrice ?? widget.booking.car.price}');
  final _sellerReceived = TextEditingController();
  final _commission = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _buyerPaid.dispose();
    _sellerReceived.dispose();
    _commission.dispose();
    super.dispose();
  }

  int? _v(TextEditingController c) => int.tryParse(c.text.trim());

  void _submit() {
    setState(() => _submitted = true);
    final paid = _v(_buyerPaid);
    final received = _v(_sellerReceived);
    final commission = _v(_commission);
    if (paid == null || paid <= 0 || received == null || received < 0 ||
        commission == null || commission < 0) {
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_DealAmounts(paid, received, commission));
  }

  Widget _field(String label, IconData icon, TextEditingController c,
      {bool positive = false}) {
    final v = _v(c);
    final bad = _submitted && (v == null || (positive && v <= 0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.title),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.blue),
              suffixText: 'ج.م',
              hintText: 'أدخل المبلغ',
              hintStyle: TextStyle(color: AppColors.hint),
              errorText: bad ? 'من فضلك أدخل مبلغ صحيح' : null,
              filled: true,
              fillColor: AppColors.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.blue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.booking.car;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _appBar('نجحت العملية'),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car_filled_outlined,
                      color: AppColors.blue, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(car.title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'بعد تأكيد البيانات هيتم تسجيل العملية كناجحة، وحذف الحجز من '
              'حجوزات المشتري، وإزالة السيارة من الصفحة الرئيسية.',
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: AppColors.subtitle),
            ),
            const SizedBox(height: 18),
            _field('المبلغ اللي دفعه المشتري', Icons.payments_outlined,
                _buyerPaid,
                positive: true),
            _field('المبلغ اللي استلمه البائع', Icons.account_balance_wallet_outlined,
                _sellerReceived),
            _field('العمولة', Icons.percent_rounded, _commission),
            const SizedBox(height: 4),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 23),
                label: const Text('تأكيد نجاح العملية',
                    style:
                        TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tone(0xFF0E9F6E),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('إلغاء',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.subtitle,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
