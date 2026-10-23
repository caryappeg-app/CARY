// Presentation: منطق شاشة "رأيك يهمنا"
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/feedback_rules.dart';
import '../../domain/entities/feedback_subject.dart';
import '../../domain/usecases/submit_feedback.dart';

enum FeedbackStatus { editing, submitting, success, failure }

class FeedbackState {
  final FeedbackSubject? subject;
  final String details;
  final FeedbackStatus status;
  final String? error;

  const FeedbackState({
    this.subject,
    this.details = '',
    this.status = FeedbackStatus.editing,
    this.error,
  });

  bool get isSubmitting => status == FeedbackStatus.submitting;

  /// زرار "إرسال" يشتغل بس لما الموضوع يتحدد والتفاصيل تتكتب
  bool get canSubmit =>
      !isSubmitting &&
      FeedbackRules.validate(subject: subject, details: details) == null;

  FeedbackState copyWith({
    FeedbackSubject? subject,
    String? details,
    FeedbackStatus? status,
    String? error,
    bool clearError = false,
  }) =>
      FeedbackState(
        subject: subject ?? this.subject,
        details: details ?? this.details,
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );
}

class FeedbackCubit extends Cubit<FeedbackState> {
  final SubmitFeedback _submitFeedback;
  final NotificationsRepository? _notifications;

  FeedbackCubit({
    required SubmitFeedback submitFeedback,
    NotificationsRepository? notifications,
  })  : _submitFeedback = submitFeedback,
        _notifications = notifications,
        super(const FeedbackState());

  static String _subjectLabel(FeedbackSubject s) => switch (s) {
        FeedbackSubject.complaint => 'شكوى',
        FeedbackSubject.suggestion => 'اقتراح',
        FeedbackSubject.inquiry => 'استفسار',
        FeedbackSubject.rating => 'تقييم',
      };

  void selectSubject(FeedbackSubject subject) => emit(state.copyWith(
        subject: subject,
        status: FeedbackStatus.editing,
        clearError: true,
      ));

  void setDetails(String text) => emit(state.copyWith(
        details: text,
        status: FeedbackStatus.editing,
        clearError: true,
      ));

  Future<void> submit({
    String senderName = '',
    String senderEmail = '',
    String senderPhone = '',
  }) async {
    final subject = state.subject;
    if (!state.canSubmit || subject == null) return;

    emit(state.copyWith(status: FeedbackStatus.submitting, clearError: true));
    try {
      await _submitFeedback(FeedbackEntry(
        subject: subject,
        details: state.details.trim(),
        senderName: senderName,
        senderEmail: senderEmail,
        senderPhone: senderPhone,
      ));
      // إشعار للأدمن والمالك: جه رأي جديد في "آراء العملاء"
      _notifications?.publish(NotificationEvents.newFeedback(
        subjectLabel: _subjectLabel(subject),
        senderName: senderName,
        details: state.details,
        senderEmail: senderEmail,
      ));
      if (!isClosed) emit(state.copyWith(status: FeedbackStatus.success));
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: FeedbackStatus.failure,
          error: mapToFailure(e).message,
        ));
      }
    }
  }
}
