// Presentation: شاشة "إدارة الإعلانات" (للأدمن والمالك).
// 4 تابات: قيد المراجعة / تم المراجعة / المرفوضة / تم بيعها.
// كل إعلان بيظهر مع بيانات صاحب الحساب (الاسم / الرقم / الجيميل) وتفاصيل السيارة،
// وفي "قيد المراجعة" فيه زر قبول ورفض (الرفض بيطلب سبب يدوي).

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/widgets/admin_search_field.dart';
import '../../../../core/widgets/date_info_row.dart';
import '../../../../core/widgets/local_image.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/formatters.dart' show formatNumber;
import '../../../../screens/ads_store.dart';
import '../../../../screens/bookings_store.dart';
import '../../../../screens/my_ad.dart';
import '../../../../screens/sell_car_tab.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../cars/presentation/cubit/cars_cubit.dart';
import '../../../cars/presentation/pages/car_details_screen.dart';

class AdsManagementPage extends StatefulWidget {
  /// true = تفتح على تبويب "قيد المراجعة" (لما المالك يضغط على إشعار إعلان جديد)
  final bool openPending;

  const AdsManagementPage({super.key, this.openPending = false});

  static Future<void> open(
    BuildContext context, {
    bool pending = false,
    CarsCubit? carsCubit,
    AccountCubit? accountCubit,
  }) {
    // الـ Routes الجديدة برّه الـ Providers، فبنمرّر الـ Cubits اللي الفورم محتاجها
    // (لو الفتح من إشعار بنمرّرهم صراحة لأن الـ context وقتها فوق الـ Providers)
    final cars = carsCubit ?? context.read<CarsCubit>();
    final account = accountCubit ?? context.read<AccountCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CarsCubit>.value(value: cars),
            BlocProvider<AccountCubit>.value(value: account),
          ],
          child: AdsManagementPage(openPending: pending),
        ),
      ),
    );
  }

  @override
  State<AdsManagementPage> createState() => _AdsManagementPageState();
}

class _AdsManagementPageState extends State<AdsManagementPage> {
  static const List<(_AdsTab, String)> _tabs = [
    (_AdsTab.all, 'الكل'),
    (_AdsTab.pending, 'قيد المراجعة'),
    (_AdsTab.approved, 'تم المراجعة'),
    (_AdsTab.rejected, 'المرفوضة'),
    (_AdsTab.sold, 'تم بيعها'),
    (_AdsTab.deleted, 'تم حذفها'),
  ];

  final _store = AdsStore.instance;
  String _query = '';

  /// البحث: رقم الهاتف / الاسم / الجيميل (صاحب الإعلان) / اسم السيارة
  bool _match(MyAd a) => matchesQuery(_query, [
        a.ownerPhone,
        a.ownerName,
        a.ownerEmail,
        a.title,
        a.brandName,
        a.model,
      ]);

  List<MyAd> _adsFor(_AdsTab t) => _rawFor(t).where(_match).toList();

  List<MyAd> _rawFor(_AdsTab t) => switch (t) {
        _AdsTab.all => _store.all,
        _AdsTab.pending => _store.byStatus(MyAdStatus.pending),
        _AdsTab.approved => _store.byStatus(MyAdStatus.approved),
        _AdsTab.rejected => _store.byStatus(MyAdStatus.rejected),
        _AdsTab.sold => _store.byStatus(MyAdStatus.sold),
        _AdsTab.deleted => _store.deleted,
      };

  @override
  void initState() {
    super.initState();
    _store.loadFromServer(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: widget.openPending ? 1 : 0, // 1 = قيد المراجعة
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.title),
          title: Text(
            'إدارة الإعلانات',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: ListenableBuilder(
              listenable: _store,
              builder: (context, _) => TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.blue,
                unselectedLabelColor: AppColors.subtitle,
                indicatorColor: AppColors.blue,
                labelStyle: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800),
                tabs: [
                  for (final t in _tabs)
                    Tab(text: '${t.$2} (${_adsFor(t.$1).length})'),
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
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) => TabBarView(
                  children: [
                    for (final t in _tabs)
                      _AdsList(
                          tab: t.$1,
                          ads: _adsFor(t.$1),
                          searching: _query.trim().isNotEmpty),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AdsTab { all, pending, approved, rejected, sold, deleted }

// =============================================================================
// قائمة إعلانات تاب واحد
// =============================================================================

class _AdsList extends StatelessWidget {
  final _AdsTab tab;
  final List<MyAd> ads;
  final bool searching;
  const _AdsList(
      {required this.tab, required this.ads, this.searching = false});

  String get _empty => searching ? 'مفيش نتائج مطابقة للبحث' : _emptyDefault;

  String get _emptyDefault => switch (tab) {
        _AdsTab.all => 'مفيش إعلانات',
        _AdsTab.pending => 'مفيش إعلانات قيد المراجعة',
        _AdsTab.approved => 'مفيش إعلانات تمت مراجعتها',
        _AdsTab.rejected => 'مفيش إعلانات مرفوضة',
        _AdsTab.sold => 'مفيش سيارات تم بيعها',
        _AdsTab.deleted => 'مفيش إعلانات محذوفة',
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => AdsStore.instance.loadFromServer(force: true),
      child: ads.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: AppColors.icon),
                        const SizedBox(height: 12),
                        Text(
                          _empty,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: ads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _ManagedAdCard(
                  key: ValueKey('${ads[i].id}|${ads[i].deletionReason}'),
                  ad: ads[i]),
            ),
    );
  }
}

// =============================================================================
// كارت إعلان واحد
// =============================================================================

class _ManagedAdCard extends StatefulWidget {
  final MyAd ad;
  const _ManagedAdCard({super.key, required this.ad});

  @override
  State<_ManagedAdCard> createState() => _ManagedAdCardState();
}

class _ManagedAdCardState extends State<_ManagedAdCard> {
  final _reason = TextEditingController();
  bool _rejecting = false;
  bool _reasonError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _approve() {
    AdsStore.instance.approve(widget.ad.id);
    _snack('تم قبول الإعلان');
  }

  void _confirmReject() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _reasonError = true);
      return;
    }
    FocusScope.of(context).unfocus();
    AdsStore.instance.reject(widget.ad.id, text);
    _snack('تم رفض الإعلان ونقله إلى المرفوضة');
  }

  void _snack(String msg) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.dark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  bool get _isDeleted => widget.ad.deletionReason != null;

  Color get _accent => _isDeleted
      ? AppColors.tone(0xFFCBD2DC)
      : switch (widget.ad.status) {
        MyAdStatus.pending => AppColors.tone(0xFFF5DFA0),
        MyAdStatus.approved => AppColors.tone(0xFFA7E8C6),
        MyAdStatus.rejected => AppColors.errorBorder,
        MyAdStatus.sold => AppColors.tone(0xFFBFD3F5),
      };

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent, width: 1.4),
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
          // الإعلان (صورة + بيانات أساسية)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _image(ad),
                const SizedBox(width: 12),
                Expanded(child: _info(ad)),
              ],
            ),
          ),

          // تاريخ ووقت إصدار الإعلان وتاريخ ووقت قبوله
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DateInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'تاريخ إصدار الإعلان',
                  value: formatDateTime(ad.createdAt),
                ),
                if (ad.approvedAt != null)
                  DateInfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'تاريخ القبول',
                    value: formatDateTime(ad.approvedAt!),
                    color: AppColors.tone(0xFF16A34A),
                  )
                else if (ad.status == MyAdStatus.pending)
                  const DateInfoRow(
                    icon: Icons.hourglass_empty_rounded,
                    label: 'تاريخ القبول',
                    value: 'في انتظار المراجعة',
                  ),
              ],
            ),
          ),

          // سبب الرفض (تحت الإعلان) في تاب المرفوضة
          if (ad.status == MyAdStatus.rejected)
            Container(
              color: AppColors.errorBg,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_rounded,
                      color: AppColors.errorText, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'سبب الرفض: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.errorText,
                          ),
                        ),
                        TextSpan(
                          text: ad.rejectionReason ?? '-',
                          style: TextStyle(color: AppColors.errorText),
                        ),
                      ]),
                      style: const TextStyle(fontSize: 14.5, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),

          // سبب الحذف (تاب "تم حذفها")
          if (_isDeleted)
            Container(
              color: AppColors.errorBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      color: AppColors.errorText, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'سبب الحذف: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.errorText,
                          ),
                        ),
                        TextSpan(
                          text: ad.deletionReason ?? '-',
                          style: TextStyle(color: AppColors.errorText),
                        ),
                      ]),
                      style: const TextStyle(fontSize: 14.5, height: 1.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'حذف نهائي',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmPurge(context, ad),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_forever_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // بيانات صاحب الحساب
          _OwnerBox(ad: ad),

          // زرار تفاصيل السيارة (بيفتح شاشة التفاصيل — عرض فقط، من غير حجز)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => _openDetails(context, ad),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.blue.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 24),
                      SizedBox(width: 8),
                      Text('تفاصيل السيارة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // حذف نهائي (للإعلانات المحذوفة)
          if (_isDeleted)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmPurge(context, ad),
                  icon: Icon(Icons.delete_forever_rounded,
                      color: AppColors.error, size: 22),
                  label: Text(
                    'حذف الإعلان نهائياً',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

          // تعديل / حذف (لكل الإعلانات اللي لسه ما اتحذفتش)
          if (!_isDeleted)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _outlineBtn('تعديل', Icons.edit_outlined,
                      AppColors.blue, () => _edit(context, ad)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _outlineBtn('حذف', Icons.delete_outline_rounded,
                      AppColors.error, () => _confirmDelete(context, ad)),
                ),
              ],
            ),
          ),

          // أزرار القبول / الرفض (قيد المراجعة فقط)
          if (ad.status == MyAdStatus.pending && !_isDeleted) _actions(),
        ],
      ),
    );
  }

  Widget _actions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tone(0xFFFAFBFD),
        border: Border(top: BorderSide(color: AppColors.tone(0xFFEDF1F6))),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_rejecting) ...[
            Text(
              'سبب الرفض',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              maxLines: 3,
              maxLength: 300,
              textInputAction: TextInputAction.newline,
              onChanged: (_) {
                if (_reasonError) setState(() => _reasonError = false);
              },
              style: TextStyle(color: AppColors.title),
              decoration: InputDecoration(
                hintText: 'اكتب سبب رفض الإعلان...',
                hintStyle: TextStyle(color: AppColors.hint),
                errorText: _reasonError ? 'من فضلك اكتب سبب الرفض' : null,
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
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _btn(
                    'تأكيد الرفض',
                    Icons.block_rounded,
                    AppColors.error,
                    _confirmReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _rejecting = false;
                      _reasonError = false;
                      _reason.clear();
                    }),
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
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _btn('قبول', Icons.check_circle_outline_rounded,
                      AppColors.tone(0xFF0E9F6E), _approve),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _btn('رفض', Icons.close_rounded, AppColors.error,
                      () => setState(() => _rejecting = true)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _btn(String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 6),
              Text(text,
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlineBtn(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 21, color: color),
        label: Text(text,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.6), width: 1.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  /// تعديل الإعلان (الحالة وصاحب الإعلان بيفضلوا زي ما هم)
  void _edit(BuildContext context, MyAd ad) {
    final cars = context.read<CarsCubit>();
    final account = context.read<AccountCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeCtx) => MultiBlocProvider(
          providers: [
            BlocProvider<CarsCubit>.value(value: cars),
            BlocProvider<AccountCubit>.value(value: account),
          ],
          child: Scaffold(
            backgroundColor: AppColors.pageBg,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.title),
            ),
            body: SellCarTab(
              editing: ad,
              adminEdit: true,
              onPublished: (updated) {
                AdsStore.instance.replace(updated);
                Navigator.of(routeCtx).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// صفحة ذكر سبب الحذف، وبعد التأكيد الإعلان بيتنقل لتاب "تم حذفها"
  Future<void> _confirmDelete(BuildContext context, MyAd ad) async {
    final reason = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => _DeleteReasonPage(ad: ad)),
    );
    if (reason == null || reason.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    AdsStore.instance.remove(ad.id, reason);
    // أي حجز نشط على السيارة دي بيبقى فاشل
    BookingsAdminStore.instance.failActiveForCar(ad.carId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('تم حذف الإعلان ونقله إلى "تم حذفها"',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  /// حذف نهائي للإعلان من سلة المحذوفات ومن السيرفر
  Future<void> _confirmPurge(BuildContext context, MyAd ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            const Text('حذف نهائي للإعلان',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف إعلان "${ad.title}" نهائياً من سلة المحذوفات؟ سيتم مسح بيانات الإعلان تماماً ولا يمكن التراجع عن هذا الإجراء.',
          style:
              TextStyle(fontSize: 14.5, color: AppColors.subtitle, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حذف نهائي',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await AdsStore.instance.purgePermanently(ad.id);
      if (context.mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text('تم حذف الإعلان نهائياً بنجاح',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.dark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
      }
    }
  }

  void _openDetails(BuildContext context, MyAd ad) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CarDetailsScreen(car: ad.toCar(), viewOnly: true),
      ),
    );
  }

  Widget _image(MyAd ad) {
    final fallback = ColoredBox(
      color: AppColors.tone(0xFFE5EAF2),
      child: Center(
        child: Icon(Icons.directions_car_filled_outlined,
            color: AppColors.icon, size: 36),
      ),
    );
    return SizedBox(
      width: 120,
      height: 116,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LocalImage(path: ad.imagePath, fallback: fallback),
      ),
    );
  }

  Widget _info(MyAd ad) {
    Widget line(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(i, size: 16, color: AppColors.icon),
              const SizedBox(width: 5),
              Expanded(
                child: Text(t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.subtitle)),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ad.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
        line(Icons.speed_rounded, '${formatNumber(ad.km)} كم'),
        line(Icons.settings_rounded, ad.transmission),
        line(Icons.location_on_outlined, ad.location),
        const SizedBox(height: 6),
        Text(
          '${formatNumber(ad.price)} ج.م',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// بيانات صاحب الحساب: الاسم / الرقم / الجيميل (مع نسخ بالضغط)
// =============================================================================

class _OwnerBox extends StatelessWidget {
  final MyAd ad;
  const _OwnerBox({required this.ad});

  String _v(String s) => s.trim().isEmpty ? 'غير متوفر' : s.trim();

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final canCopy = value.trim().isNotEmpty;
    return InkWell(
      onTap: !canCopy
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: value.trim()));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text('تم نسخ $label'),
                  behavior: SnackBarBehavior.floating,
                ));
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.blue),
            const SizedBox(width: 8),
            Text('$label: ',
                style: TextStyle(fontSize: 13.5, color: AppColors.subtitle)),
            Expanded(
              child: Text(
                _v(value),
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.tileBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات صاحب الحساب',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
          _row(context, Icons.person_outline_rounded, 'الاسم', ad.ownerName),
          _row(context, Icons.phone_outlined, 'الرقم', ad.ownerPhone),
          _row(context, Icons.email_outlined, 'الجيميل', ad.ownerEmail),
        ],
      ),
    );
  }
}

// =============================================================================
// صفحة سبب الحذف
// =============================================================================

class _DeleteReasonPage extends StatefulWidget {
  final MyAd ad;
  const _DeleteReasonPage({required this.ad});

  @override
  State<_DeleteReasonPage> createState() => _DeleteReasonPageState();
}

class _DeleteReasonPageState extends State<_DeleteReasonPage> {
  final _reason = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _error = true);
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final onHome = ad.isCatalog || ad.status == MyAdStatus.approved;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.title),
        title: Text(
          'حذف الإعلان',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
      ),
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
                    child: Text(
                      ad.title,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onHome) ...[
              const SizedBox(height: 10),
              Text(
                'الإعلان ده معروض في الصفحة الرئيسية وهيتشال منها بعد الحذف.',
                style: TextStyle(
                    fontSize: 13.5, height: 1.5, color: AppColors.subtitle),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'سبب الحذف',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              maxLines: 5,
              maxLength: 300,
              textInputAction: TextInputAction.newline,
              onChanged: (_) {
                if (_error) setState(() => _error = false);
              },
              style: TextStyle(color: AppColors.title),
              decoration: InputDecoration(
                hintText: 'اكتب سبب حذف الإعلان...',
                hintStyle: TextStyle(color: AppColors.hint),
                errorText: _error ? 'من فضلك اكتب سبب الحذف' : null,
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
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.delete_outline_rounded, size: 23),
                label: const Text('تأكيد الحذف',
                    style:
                        TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
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
