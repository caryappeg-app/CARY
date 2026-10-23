// Presentation: منطق تاب حسابي
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/sign_out.dart';

class AccountState {
  final UserProfile? profile;
  final bool loaded;
  const AccountState({this.profile, this.loaded = false});
}

class AccountCubit extends Cubit<AccountState> {
  final GetUserProfile _getUserProfile;
  final SignOut _signOut;

  AccountCubit({
    required GetUserProfile getUserProfile,
    required SignOut signOut,
  })  : _getUserProfile = getUserProfile,
        _signOut = signOut,
        super(const AccountState());

  Future<void> load() async {
    UserProfile? profile;
    try {
      profile = await _getUserProfile();
    } catch (_) {
      profile = null;
    }
    if (!isClosed) emit(AccountState(profile: profile, loaded: true));
  }

  /// تسجيل الخروج: بيمسح بيانات الجلسة من التخزين الآمن
  Future<void> signOut() async {
    try {
      await _signOut();
    } catch (_) {
      // حتى لو فشل المسح، بنخرج المستخدم من الشاشة
    }
    if (!isClosed) emit(const AccountState(loaded: true));
  }
}
