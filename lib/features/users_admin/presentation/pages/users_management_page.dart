// Presentation: شاشة "إدارة المستخدمين" (للمالك فقط).
// بتعرض كل اللي عاملين حساب: الاسم + الإيميل + الهاتف + نوع الحساب + الحالة،
// ومع كل مستخدم: تعديل البيانات وتغيير حالة الحساب (نشط / موقوف / محظور).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/admin_search_field.dart';
import '../../../account/domain/entities/user_profile.dart' show UserRole, UserRoleX;
import '../../domain/entities/managed_user.dart';
import '../cubit/users_admin_cubit.dart';

extension UserRoleUi on UserRole {
  String get description => switch (this) {
        UserRole.owner => 'كل الصلاحيات + إدارة المستخدمين',
        UserRole.admin => 'إدارة الإعلانات والحجوزات وآراء العملاء',
        UserRole.user => 'استخدام التطبيق كعميل عادي',
      };

  IconData get icon => switch (this) {
        UserRole.owner => Icons.workspace_premium_outlined,
        UserRole.admin => Icons.admin_panel_settings_outlined,
        UserRole.user => Icons.person_outline_rounded,
      };

  Color get color => switch (this) {
        UserRole.owner => AppColors.tone(0xFF7C3AED),
        UserRole.admin => AppColors.tone(0xFF1D4ED8),
        UserRole.user => AppColors.tone(0xFF0E9F6E),
      };
}

class UsersManagementPage extends StatelessWidget {
  const UsersManagementPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider<UsersAdminCubit>(
            create: (_) => Injector.instance.createUsersAdminCubit()..load(),
            child: const UsersManagementPage(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.title),
        title: Text(
          'إدارة المستخدمين',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'ابحث بالاسم أو الجيميل أو رقم الهاتف...',
            onChanged: context.read<UsersAdminCubit>().setQuery,
          ),
          const _FilterBar(),
          Expanded(
            child: BlocBuilder<UsersAdminCubit, UsersAdminState>(
              builder: (context, state) {
                if (state.status == UsersAdminStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == UsersAdminStatus.failure &&
                    state.users.isEmpty) {
                  return _Message(
                    icon: Icons.cloud_off_rounded,
                    text: state.error ?? 'تعذّر تحميل المستخدمين',
                    onRetry: context.read<UsersAdminCubit>().load,
                  );
                }
                final list = state.visible;
                return RefreshIndicator(
                  onRefresh: context.read<UsersAdminCubit>().load,
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 320,
                              child: _Message(
                                icon: Icons.group_off_outlined,
                                text: 'مفيش مستخدمين مطابقين',
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _UserCard(user: list[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- الفلتر

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersAdminCubit, UsersAdminState>(
      builder: (context, state) {
        final cubit = context.read<UsersAdminCubit>();
        Widget chip(String label, UserRole? role) {
          final selected = state.filter == role;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text('$label (${state.countOf(role)})'),
              selected: selected,
              onSelected: (_) => cubit.setFilter(role),
              showCheckmark: false,
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.blue,
              side: BorderSide(
                  color: selected ? AppColors.blue : AppColors.fieldBorder),
              labelStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.subtitle,
              ),
            ),
          );
        }

        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip('الكل', null),
              for (final r in UserRole.values) chip(r.label, r),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- الكارت

String _formatDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}/${two(l.month)}/${two(l.day)}';
}

class _UserCard extends StatelessWidget {
  final ManagedUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.trim();
    final color = user.role.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.tileBg,
                  shape: BoxShape.circle,
                ),
                child: name.isEmpty
                    ? Icon(Icons.person_rounded, color: AppColors.blue)
                    : Text(
                        String.fromCharCode(name.runes.first),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'بدون اسم' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                  ],
                ),
              ),
              // حالة الحساب (مالك / أدمن / مستخدم)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(user.role.icon, size: 16, color: color),
                    const SizedBox(width: 5),
                    Text(
                      user.role.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.mail_outline_rounded,
              value: user.email,
              emptyText: 'البريد غير متوفر'),
          _InfoRow(
              icon: Icons.phone_outlined,
              value: user.phone,
              emptyText: 'رقم الهاتف غير متوفر'),
          if (user.createdAt != null)
            _InfoRow(
                icon: Icons.event_outlined,
                value: 'تاريخ التسجيل: ${_formatDate(user.createdAt)}',
                emptyText: ''),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.fieldBorder),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _EditUserSheet.show(context, user),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل البيانات'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: BorderSide(color: AppColors.fieldBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRoleSheet(context, user),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                    label: const Text('حالة الحساب'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String emptyText;
  const _InfoRow(
      {required this.icon, required this.value, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    final has = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.subtitle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              has ? value : emptyText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: has ? AppColors.title : AppColors.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.hint),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- تغيير حالة الحساب

Future<void> _showRoleSheet(BuildContext context, ManagedUser user) async {
  final cubit = context.read<UsersAdminCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final name = user.fullName.trim().isEmpty ? 'المستخدم' : user.fullName.trim();

  final picked = await showModalBottomSheet<UserRole>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حالة حساب $name',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            for (final r in UserRole.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(r.icon, color: r.color),
                title: Text(r.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.title)),
                subtitle: Text(r.description,
                    style: TextStyle(color: AppColors.subtitle)),
                trailing: r == user.role
                    ? Icon(Icons.check_rounded, color: AppColors.blue)
                    : null,
                onTap: () => Navigator.of(ctx).pop(r),
              ),
          ],
        ),
      ),
    ),
  );

  if (picked == null || picked == user.role || !context.mounted) return;

  // منح صلاحية "مالك" قرار حساس: بنطلب تأكيد
  if (picked == UserRole.owner) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('تأكيد',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.title)),
        content: Text(
          'هل تريد جعل $name "مالك"؟ هيبقى عنده كل الصلاحيات بما فيها إدارة المستخدمين.',
          style: TextStyle(height: 1.6, color: AppColors.subtitle),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true) return;
  }

  final error = await cubit.setRole(user.id, picked);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(
        error ?? 'تم تغيير حالة الحساب إلى "${picked.label}"',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: error == null ? AppColors.dark : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
}

// ---------------------------------------------------------------- تعديل البيانات

class _EditUserSheet extends StatefulWidget {
  final ManagedUser user;
  final UsersAdminCubit cubit;
  const _EditUserSheet({required this.user, required this.cubit});

  static Future<void> show(BuildContext context, ManagedUser user) {
    final cubit = context.read<UsersAdminCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditUserSheet(user: user, cubit: cubit),
    );
  }

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _email = TextEditingController(text: widget.user.email);
  late final _phone = TextEditingController(text: widget.user.phone);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.subtitle),
        filled: true,
        fillColor: AppColors.pageBg,
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
          borderSide: BorderSide(color: AppColors.blue, width: 1.6),
        ),
      );

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.cubit.updateUser(
      id: widget.user.id,
      fullName: _name.text,
      email: _email.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    final nav = Navigator.of(context);
    final root = ScaffoldMessenger.of(context);
    nav.pop();
    root
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('تم حفظ بيانات المستخدم',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.dark,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 18, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تعديل بيانات المستخدم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: _dec('الاسم الكامل', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              decoration: _dec('البريد الإلكتروني', Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: _dec('رقم الهاتف', Icons.phone_outlined),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('حفظ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
