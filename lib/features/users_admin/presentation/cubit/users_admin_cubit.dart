// Presentation: منطق شاشة "إدارة المستخدمين": تحميل + فلتر بحالة الحساب + بحث + تعديل + تغيير حالة الحساب (مالك / أدمن / مستخدم)
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../../account/domain/entities/user_profile.dart' show UserRole;
import '../../domain/entities/managed_user.dart';
import '../../domain/usecases/get_managed_users.dart';
import '../../domain/usecases/set_user_role.dart';
import '../../domain/usecases/update_managed_user.dart';

enum UsersAdminStatus { loading, loaded, failure }

class UsersAdminState {
  final UsersAdminStatus status;
  final List<ManagedUser> users;
  final UserRole? filter; // null = الكل
  final String query;
  final String? error;

  const UsersAdminState({
    this.status = UsersAdminStatus.loading,
    this.users = const [],
    this.filter,
    this.query = '',
    this.error,
  });

  int countOf(UserRole? r) =>
      r == null ? users.length : users.where((u) => u.role == r).length;

  /// بعد الفلتر والبحث (الاسم / الإيميل / الرقم)
  List<ManagedUser> get visible {
    final q = query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
    return users.where((u) {
      if (filter != null && u.role != filter) return false;
      if (q.isEmpty) return true;
      if (u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q)) {
        return true;
      }
      return qDigits.length >= 3 && u.phone.contains(qDigits);
    }).toList();
  }

  UsersAdminState copyWith({
    UsersAdminStatus? status,
    List<ManagedUser>? users,
    UserRole? filter,
    bool clearFilter = false,
    String? query,
    String? error,
  }) =>
      UsersAdminState(
        status: status ?? this.status,
        users: users ?? this.users,
        filter: clearFilter ? null : (filter ?? this.filter),
        query: query ?? this.query,
        error: error,
      );
}

class UsersAdminCubit extends Cubit<UsersAdminState> {
  final GetManagedUsers _getUsers;
  final UpdateManagedUser _updateUser;
  final SetUserRole _setRole;

  UsersAdminCubit({
    required GetManagedUsers getUsers,
    required UpdateManagedUser updateUser,
    required SetUserRole setRole,
  })  : _getUsers = getUsers,
        _updateUser = updateUser,
        _setRole = setRole,
        super(const UsersAdminState());

  Future<void> load() async {
    if (state.users.isEmpty) {
      emit(state.copyWith(status: UsersAdminStatus.loading));
    }
    try {
      final users = await _getUsers();
      if (!isClosed) {
        emit(state.copyWith(status: UsersAdminStatus.loaded, users: users));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: UsersAdminStatus.failure,
          error: mapToFailure(e).message,
        ));
      }
    }
  }

  void setFilter(UserRole? role) => emit(role == null
      ? state.copyWith(clearFilter: true)
      : state.copyWith(filter: role));

  void setQuery(String value) =>
      emit(state.copyWith(query: InputSanitizer.searchQuery(value)));

  /// بيرجّع null لو نجح، أو رسالة الخطأ
  Future<String?> updateUser({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) =>
      _apply(() => _updateUser(
          id: id, fullName: fullName, email: email, phone: phone));

  Future<String?> setRole(String id, UserRole role) =>
      _apply(() => _setRole(id: id, role: role));

  Future<String?> _apply(Future<ManagedUser> Function() action) async {
    try {
      final updated = await action();
      if (!isClosed) {
        emit(state.copyWith(
          users: [
            for (final u in state.users) u.id == updated.id ? updated : u,
          ],
        ));
      }
      return null;
    } catch (e) {
      return mapToFailure(e).message;
    }
  }
}
