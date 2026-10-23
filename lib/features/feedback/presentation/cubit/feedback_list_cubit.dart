// Presentation: منطق شاشة "آراء العملاء" (للمالك والأدمن): تحميل + فلتر بالتصنيف + بحث
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/feedback_subject.dart';
import '../../domain/usecases/delete_feedback.dart';
import '../../domain/usecases/get_all_feedback.dart';

enum FeedbackListStatus { loading, loaded, failure }

class FeedbackListState {
  final FeedbackListStatus status;
  final List<FeedbackEntry> items;
  final FeedbackSubject? filter; // null = الكل
  final String query;
  final String? error;

  const FeedbackListState({
    this.status = FeedbackListStatus.loading,
    this.items = const [],
    this.filter,
    this.query = '',
    this.error,
  });

  int countOf(FeedbackSubject? s) =>
      s == null ? items.length : items.where((e) => e.subject == s).length;

  /// الآراء بعد الفلتر والبحث (الاسم / الإيميل / الرقم / المحتوى)
  List<FeedbackEntry> get visible {
    final q = query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
    return items.where((e) {
      if (filter != null && e.subject != filter) return false;
      if (q.isEmpty) return true;
      if (e.senderName.toLowerCase().contains(q) ||
          e.senderEmail.toLowerCase().contains(q) ||
          e.senderPhone.contains(q) ||
          e.details.toLowerCase().contains(q)) {
        return true;
      }
      return qDigits.length >= 3 &&
          e.senderPhone.replaceAll(RegExp(r'[^0-9]'), '').contains(qDigits);
    }).toList();
  }

  FeedbackListState copyWith({
    FeedbackListStatus? status,
    List<FeedbackEntry>? items,
    FeedbackSubject? filter,
    bool clearFilter = false,
    String? query,
    String? error,
  }) =>
      FeedbackListState(
        status: status ?? this.status,
        items: items ?? this.items,
        filter: clearFilter ? null : (filter ?? this.filter),
        query: query ?? this.query,
        error: error,
      );
}

class FeedbackListCubit extends Cubit<FeedbackListState> {
  final GetAllFeedback _getAllFeedback;
  final DeleteFeedback _deleteFeedback;

  FeedbackListCubit({
    required GetAllFeedback getAllFeedback,
    required DeleteFeedback deleteFeedback,
  })  : _getAllFeedback = getAllFeedback,
        _deleteFeedback = deleteFeedback,
        super(const FeedbackListState());

  Future<void> load() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(status: FeedbackListStatus.loading));
    }
    try {
      final items = await _getAllFeedback();
      if (!isClosed) {
        emit(state.copyWith(status: FeedbackListStatus.loaded, items: items));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: FeedbackListStatus.failure,
          error: mapToFailure(e).message,
        ));
      }
    }
  }

  /// حذف رأي (المالك فقط). بيتشال من الشاشة فورًا، ولو السيرفر رفض بيرجع ويظهر السبب.
  /// بيرجّع null لو نجح، أو رسالة الخطأ.
  Future<String?> delete(String id) async {
    if (id.isEmpty) return 'تعذّر حذف الرأي';
    final before = state.items;
    emit(state.copyWith(items: before.where((e) => e.id != id).toList()));
    try {
      await _deleteFeedback(id);
      return null;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(items: before));
      return mapToFailure(e).message;
    }
  }

  void setFilter(FeedbackSubject? subject) => emit(
      subject == null ? state.copyWith(clearFilter: true) : state.copyWith(filter: subject));

  void setQuery(String value) =>
      emit(state.copyWith(query: InputSanitizer.searchQuery(value)));
}
