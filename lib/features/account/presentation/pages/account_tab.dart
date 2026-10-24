// Presentation: تاب حسابي — كارت المستخدم + خانة "معلومات الحساب" (بتتفتح بالضغط)
// ملحوظة: ألوان AppColors بتتغير مع الوضع الداكن، فمفيش `const` على أي حاجة بتستخدمها.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/theme_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/external_launcher.dart';
import '../../../../screens/login_screen.dart';
import '../../../ads/presentation/pages/ads_management_page.dart';
import '../../../bookings_admin/presentation/pages/bookings_management_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cars/presentation/cubit/bookings_cubit.dart';
import '../../../cars/presentation/cubit/favorites_cubit.dart';
import '../../../feedback/presentation/pages/feedback_management_page.dart';
import '../../../users_admin/presentation/pages/users_management_page.dart';
import '../../../feedback/presentation/pages/feedback_page.dart';
import '../../../home/presentation/widgets/app_top_bar.dart';
import '../../domain/entities/user_profile.dart';
import '../cubit/account_cubit.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  // ---------------------------------------------------------------- actions

  /// التواصل مع الدعم: بيفتح واتساب على رقم الدعم (للمستخدمين فقط)
  Future<void> _contactSupport(BuildContext context, UserProfile? p) async {
    final name = (p?.fullName ?? '').trim();
    final message = name.isEmpty
        ? 'مرحبًا فريق CARY، أحتاج مساعدة'
        : 'مرحبًا فريق CARY، أنا $name وأحتاج مساعدة';

    final ok = await ExternalLauncher.openWhatsApp(
      AppConfig.supportWhatsapp,
      message: message,
    );
    if (!ok && context.mounted) {
      _showSnack(context, 'تعذّر فتح واتساب، تأكد إنه متسطّب على جهازك');
    }
  }

  void _openFeedback(BuildContext context, UserProfile? p) {
    FeedbackPage.open(
      context,
      senderName: (p?.fullName ?? '').trim(),
      senderEmail: (p?.email ?? '').trim(),
      senderPhone: (p?.phone ?? '').trim(),
    );
  }

  /// تسجيل الخروج (لكل الحالات: مالك / أدمن / مستخدم)
  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: ThemeController.barrierColor,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
        content: Text(
          'هل تريد تسجيل الخروج من حسابك؟',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 15, height: 1.6, color: AppColors.subtitle),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'خروج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // بنمسك كل حاجة قبل الـ await عشان الـ context
    final nav = Navigator.of(context);
    final account = context.read<AccountCubit>();
    final auth = context.read<AuthCubit>();
    final favorites = context.read<FavoritesCubit>();
    final bookings = context.read<BookingsCubit>();

    await account.signOut();
    await auth.signOut(); // بيمسح Access/Refresh Token من التخزين الآمن
    // بيانات المستخدم المحلية (مفضلات / حجوزات) متفضلش للمستخدم اللي بعده
    await favorites.clear();
    await bookings.clear();

    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.dark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(),
        Expanded(
          child: BlocBuilder<AccountCubit, AccountState>(
            builder: (context, state) {
              final profile = state.profile;
              final role = profile?.role ?? UserRole.user;

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _ProfileHeader(
                          name: profile?.fullName ?? '',
                          role: role,
                        ),
                        const SizedBox(height: 14),
                        _AccountInfoCard(profile: profile),
                        // إدارة الإعلانات: للمالك والأدمن فقط
                        if (role == UserRole.owner ||
                            role == UserRole.admin) ...[
                          const SizedBox(height: 14),
                          _ActionTile(
                            icon: Icons.fact_check_outlined,
                            title: 'إدارة الإعلانات',
                            subtitle: 'مراجعة وقبول ورفض إعلانات السيارات',
                            onTap: () => AdsManagementPage.open(context),
                          ),
                          const SizedBox(height: 14),
                          _ActionTile(
                            icon: Icons.event_note_outlined,
                            title: 'إدارة الحجوزات',
                            subtitle: 'الحجوزات النشطة والعمليات الناجحة والفاشلة',
                            onTap: () => BookingsManagementPage.open(context,
                                accountCubit: context.read<AccountCubit>()),
                          ),
                          const SizedBox(height: 14),
                          _ActionTile(
                            icon: Icons.forum_outlined,
                            title: 'آراء العملاء',
                            subtitle: 'الشكاوى والاقتراحات والاستفسارات والتقييمات',
                            onTap: () => FeedbackManagementPage.open(context),
                          ),
                          // إدارة المستخدمين: للمالك فقط
                          if (role == UserRole.owner) ...[
                            const SizedBox(height: 14),
                            _ActionTile(
                              icon: Icons.manage_accounts_outlined,
                              title: 'إدارة المستخدمين',
                              subtitle: 'كل الحسابات، تعديل البيانات وحالة الحساب',
                              onTap: () => UsersManagementPage.open(context),
                            ),
                          ],
                        ],
                        // رأيك يهمنا + التواصل مع الدعم: للمستخدمين فقط (مش للمالك أو الأدمن)
                        if (role == UserRole.user) ...[
                          const SizedBox(height: 14),
                          _ActionTile(
                            icon: Icons.rate_review_outlined,
                            title: 'رأيك يهمنا',
                            subtitle: 'شكوى، اقتراح، استفسار أو تقييم',
                            onTap: () => _openFeedback(context, profile),
                          ),
                          const SizedBox(height: 14),
                          _ActionTile(
                            icon: Icons.support_agent_rounded,
                            title: 'التواصل مع الدعم',
                            subtitle: 'تواصل معنا عبر واتساب',
                            accent: AppColors.tone(0xFF16A34A),
                            accentBg: AppColors.tone(0xFFDCFCE7),
                            onTap: () => _contactSupport(context, profile),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  // زرار تسجيل الخروج ثابت في أسفل الصفحة
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _LogoutButton(onTap: () => _logout(context)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration({Color? color}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: AppColors.tone(0xFFEDF1F6)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ],
);

// =============================================================================
// كارت المستخدم
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  final String name;
  final UserRole role;
  const _ProfileHeader({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final hasName = trimmed.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tileBg,
              shape: BoxShape.circle,
            ),
            child: hasName
                ? Text(
              String.fromCharCode(trimmed.runes.first),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
              ),
            )
                : Icon(Icons.person_rounded, color: AppColors.blue, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? trimmed : 'مستخدم CARY',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ حالة الحساب (مالك / أدمن / مستخدم) جنب "حسابي"
                Row(
                  children: [
                    Text(
                      'حسابي',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.subtitle),
                    ),
                    const SizedBox(width: 8),
                    _RoleChip(role: role),
                  ],
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
// شارة حالة الحساب (مالك / أدمن / مستخدم)
// =============================================================================

class _RoleChip extends StatelessWidget {
  final UserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      UserRole.owner => (const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
      UserRole.admin => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      UserRole.user => (const Color(0xFFF1F4F9), const Color(0xFF64748B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

// =============================================================================
// صفوف الإجراءات (رأيك يهمنا / التواصل مع الدعم) + زرار تسجيل الخروج
// =============================================================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;
  final Color? accentBg;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
    this.accentBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentBg ?? AppColors.tileBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent ?? AppColors.blue, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.subtitle),
                      ),
                    ],
                  ),
                ),
                // سهم "التالي" ناحية الشمال (LTR إجباري عشان ميتقلبش)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Icon(Icons.chevron_left_rounded,
                      color: AppColors.icon, size: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.errorBorder, width: 1.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 10),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.errorText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// معلومات الحساب
// =============================================================================

class _AccountInfoCard extends StatefulWidget {
  final UserProfile? profile;
  const _AccountInfoCard({this.profile});

  @override
  State<_AccountInfoCard> createState() => _AccountInfoCardState();
}

class _AccountInfoCardState extends State<_AccountInfoCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Container(
      decoration: _cardDecoration(),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.tileBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.badge_outlined,
                          color: AppColors.blue, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معلومات الحساب',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.title,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الاسم، البريد الإلكتروني، رقم الهاتف',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.subtitle),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.icon, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(height: 1, color: AppColors.fieldBorder),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'الاسم الكامل',
                      value: p?.fullName ?? '',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'البريد الإلكتروني',
                      value: p?.email ?? '',
                      ltr: true,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.smartphone_outlined,
                      label: 'رقم الهاتف',
                      value: p?.phone ?? '',
                      ltr: true,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'حالة الحساب',
                      value: p?.role.label ?? 'مستخدم',
                    ),
                  ],
                ),
              )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// سطر بيانات: أيقونة + العنوان + القيمة، وعلى الشمال زر النسخ.
class _InfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;

  /// الإيميل والهاتف بيتعرضوا من الشمال لليمين جوه النص العربي
  final bool ltr;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value.trim()));
    HapticFeedback.selectionClick();
    if (!mounted) return;

    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'تم نسخ ${widget.label}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.dark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final has = widget.value.trim().isNotEmpty;
    final green = AppColors.tone(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: AppColors.blue, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 3),
                if (has)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.value.trim(),
                      maxLines: 1,
                      textDirection:
                      widget.ltr ? TextDirection.ltr : TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                  )
                else
                  Text(
                    'غير متوفر',
                    style: TextStyle(fontSize: 15, color: AppColors.hint),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'نسخ ${widget.label}',
            child: Material(
              color: _copied
                  ? AppColors.tone(0xFFDCFCE7)
                  : AppColors.tileBg,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: has ? _copy : null,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      key: ValueKey(_copied),
                      size: 22,
                      color: _copied
                          ? green
                          : (has ? AppColors.blue : AppColors.hint),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}