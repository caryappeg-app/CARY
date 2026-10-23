// Presentation: شاشة الإشعارات (من جرس الهيدر).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/push/notification_router.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

extension NotificationTypeUi on NotificationType {
  IconData get icon => switch (this) {
        NotificationType.adApproved => Icons.check_circle_outline_rounded,
        NotificationType.adRejected => Icons.cancel_outlined,
        NotificationType.carSold => Icons.sell_outlined,
        NotificationType.newFeedback => Icons.rate_review_outlined,
        NotificationType.newAd => Icons.campaign_outlined,
        NotificationType.newBooking => Icons.event_available_outlined,
      };

  Color get color => switch (this) {
        NotificationType.adApproved => AppColors.tone(0xFF0E9F6E),
        NotificationType.adRejected => AppColors.error,
        NotificationType.carSold => AppColors.tone(0xFFD97706),
        NotificationType.newFeedback => AppColors.tone(0xFF7C3AED),
        NotificationType.newAd => AppColors.blue,
        NotificationType.newBooking => AppColors.tone(0xFF0891B2),
      };
}

String _ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'دلوقتي';
  if (diff.inMinutes < 60) return 'من ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'من ${diff.inHours} ساعة';
  return 'من ${diff.inDays} يوم';
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
      );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.title),
        title: Text(
          'الإشعارات',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.title),
            onSelected: (v) =>
                v == 'read' ? cubit.markAllRead() : cubit.clearAll(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'read', child: Text('تعليم الكل كمقروء')),
              PopupMenuItem(value: 'clear', child: Text('مسح الكل')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: AppColors.hint),
                  const SizedBox(height: 10),
                  Text(
                    'مفيش إشعارات لسه',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final n = state.items[i];
              return Dismissible(
                key: ValueKey(n.id),
                onDismissed: (_) => cubit.remove(n.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
                child: _NotificationTile(
                  notification: n,
                  onTap: () {
                    cubit.markRead(n.id);
                    // إشعارات الإدارة بتفتح صفحة إدارتها (الشاشة الرئيسية هي اللي بتفتحها)
                    switch (n.type) {
                      case NotificationType.newBooking:
                      case NotificationType.newAd:
                      case NotificationType.newFeedback:
                        NotificationRouter.instance.open(n.type.name);
                      default:
                        break;
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final color = n.type.color;
    return Material(
      color: n.read ? AppColors.surface : AppColors.tileBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.type.icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight:
                                  n.read ? FontWeight.w700 : FontWeight.w900,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ago(n.createdAt),
                      style: TextStyle(fontSize: 12, color: AppColors.hint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
