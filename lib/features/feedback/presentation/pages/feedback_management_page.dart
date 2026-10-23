// Presentation: شاشة "آراء العملاء" (للمالك والأدمن).
// بتعرض كل شكوى / اقتراح / استفسار / تقييم: التصنيف + الاسم + الإيميل + رقم الهاتف + المحتوى + الوقت.
// فلتر بالتصنيف + بحث + سحب للتحديث.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/admin_search_field.dart';
import '../../../account/domain/entities/user_profile.dart' show UserRole;
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/feedback_subject.dart';
import '../cubit/feedback_list_cubit.dart';
import 'feedback_page.dart' show FeedbackSubjectUi;

class FeedbackManagementPage extends StatelessWidget {
  const FeedbackManagementPage({super.key});

  static Future<void> open(BuildContext context, {AccountCubit? accountCubit}) {
    // الـ Route الجديد برّه الـ Providers، فبنمرّر AccountCubit (عشان نعرف المستخدم مالك ولا لأ)
    final account = accountCubit ?? context.read<AccountCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<FeedbackListCubit>(
              create: (_) =>
                  Injector.instance.createFeedbackListCubit()..load(),
            ),
            BlocProvider<AccountCubit>.value(value: account),
          ],
          child: const FeedbackManagementPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // زر الحذف للمالك فقط (والسيرفر برضه بيرفض أي حد غيره)
    final isOwner = context.select<AccountCubit, bool>(
        (c) => c.state.profile?.role == UserRole.owner);
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.title),
        title: Text(
          'آراء العملاء',
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
            hint: 'ابحث بالاسم أو الجيميل أو رقم الهاتف أو المحتوى...',
            onChanged: context.read<FeedbackListCubit>().setQuery,
          ),
          const _FilterBar(),
          Expanded(
            child: BlocBuilder<FeedbackListCubit, FeedbackListState>(
              builder: (context, state) {
                if (state.status == FeedbackListStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == FeedbackListStatus.failure &&
                    state.items.isEmpty) {
                  return _Message(
                    icon: Icons.cloud_off_rounded,
                    text: state.error ?? 'تعذّر تحميل الآراء',
                    onRetry: context.read<FeedbackListCubit>().load,
                  );
                }
                final list = state.visible;
                return RefreshIndicator(
                  onRefresh: context.read<FeedbackListCubit>().load,
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 320,
                              child: _Message(
                                icon: Icons.inbox_outlined,
                                text: state.items.isEmpty
                                    ? 'لسه مفيش آراء من العملاء'
                                    : 'مفيش نتائج مطابقة',
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _FeedbackCard(
                            entry: list[i],
                            onDelete: isOwner
                                ? () => _confirmDelete(context, list[i])
                                : null,
                          ),
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
    return BlocBuilder<FeedbackListCubit, FeedbackListState>(
      builder: (context, state) {
        final cubit = context.read<FeedbackListCubit>();
        Widget chip(String label, FeedbackSubject? subject) {
          final selected = state.filter == subject;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text('$label (${state.countOf(subject)})'),
              selected: selected,
              onSelected: (_) => cubit.setFilter(subject),
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
              for (final s in FeedbackSubject.values) chip(s.label, s),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- الكارت

Color _subjectColor(FeedbackSubject s) => switch (s) {
      FeedbackSubject.complaint => AppColors.error,
      FeedbackSubject.suggestion => AppColors.tone(0xFFD97706),
      FeedbackSubject.inquiry => AppColors.blue,
      FeedbackSubject.rating => AppColors.tone(0xFF0E9F6E),
    };

String _formatDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}/${two(l.month)}/${two(l.day)}  ${two(l.hour)}:${two(l.minute)}';
}

/// تأكيد ثم حذف الرأي (المالك فقط)
Future<void> _confirmDelete(BuildContext context, FeedbackEntry entry) async {
  final cubit = context.read<FeedbackListCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف الرأي؟'),
      content: const Text('هيتحذف الرأي نهائيًا ومش هتقدر ترجّعه.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('حذف', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final error = await cubit.delete(entry.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error ?? 'تم حذف الرأي')));
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackEntry entry;

  /// بيظهر للمالك فقط
  final VoidCallback? onDelete;
  const _FeedbackCard({required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(entry.subject);
    final name = entry.senderName.trim();

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
              // التصنيف
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
                    Icon(entry.subject.icon, size: 16, color: color),
                    const SizedBox(width: 5),
                    Text(
                      entry.subject.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(entry.createdAt),
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12, color: AppColors.hint),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'حذف الرأي',
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 22, color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // بيانات صاحب الرأي
          _InfoRow(
            icon: Icons.person_outline_rounded,
            value: name,
            emptyText: 'الاسم غير متوفر',
            bold: true,
          ),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            value: entry.senderEmail,
            emptyText: 'البريد غير متوفر',
            copyable: true,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            value: entry.senderPhone,
            emptyText: 'رقم الهاتف غير متوفر',
            copyable: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.fieldBorder),
          ),
          // المحتوى
          SelectableText(
            entry.details,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.title,
            ),
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
  final bool bold;
  final bool copyable;

  const _InfoRow({
    required this.icon,
    required this.value,
    required this.emptyText,
    this.bold = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final has = value.trim().isNotEmpty;
    final text = Text(
      has ? value : emptyText,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: bold ? 16 : 14,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: has ? AppColors.title : AppColors.hint,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        // الضغط على الإيميل / الرقم بينسخه
        onTap: copyable && has
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('تم النسخ'),
                    duration: Duration(seconds: 1),
                  ));
              }
            : null,
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.subtitle),
            const SizedBox(width: 8),
            Expanded(child: text),
          ],
        ),
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
