// Core: نقطة تجميع الاعتماديات (Composition Root) — DI يدوي من غير حزم إضافية.
//
// لما تربط الداتابيز (Supabase / Firebase / REST): بدّل MockCarRemoteDataSource
// بالنسخة الحقيقية هنا بس، وباقي التطبيق (Domain + UI) ميتغيرش.
import '../../screens/ads_store.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/dio_api_client.dart';
import '../network/session_events.dart';
import '../security/flutter_secure_storage_impl.dart';
import '../security/secure_storage.dart';
import '../security/token_store.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/mock_auth_remote_data_source.dart';
import '../../features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import '../../features/ads/data/ads_remote.dart';
import '../../features/notifications/data/repositories/supabase_notifications_repository.dart';
import '../../features/auth/data/datasources/email_verification_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/cars/data/datasources/supabase_car_remote_data_source.dart';
import '../../features/cars/data/repositories/supabase_bookings_repository.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/get_user_profile.dart';
import '../../features/account/domain/usecases/sign_out.dart';
import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/cars/data/datasources/bookings_local_data_source.dart';
import '../../features/cars/data/datasources/car_local_data_source.dart';
import '../../features/cars/data/datasources/car_remote_data_source.dart';
import '../../features/cars/data/datasources/mock_car_remote_data_source.dart';
import '../../features/cars/data/datasources/saved_cars_local_data_source.dart';
import '../../features/cars/data/repositories/bookings_repository_impl.dart';
import '../../features/cars/data/repositories/car_repository_impl.dart';
import '../../features/cars/data/repositories/favorites_repository_impl.dart';
import '../../features/cars/domain/repositories/bookings_repository.dart';
import '../../features/cars/domain/repositories/car_repository.dart';
import '../../features/cars/domain/repositories/favorites_repository.dart';
import '../../features/cars/domain/usecases/book_car.dart';
import '../../features/cars/domain/usecases/clear_bookings.dart';
import '../../features/cars/domain/usecases/remove_booking.dart';
import '../../features/cars/domain/usecases/clear_favorites.dart';
import '../../features/cars/domain/usecases/get_bookings.dart';
import '../../features/cars/domain/usecases/get_brand_counts.dart';
import '../../features/cars/domain/usecases/get_cars.dart';
import '../../features/cars/domain/usecases/get_favorites.dart';
import '../../features/cars/domain/usecases/toggle_favorite.dart';
import '../../features/cars/presentation/cubit/bookings_cubit.dart';
import '../../features/cars/presentation/cubit/cars_cubit.dart';
import '../../features/cars/presentation/cubit/favorites_cubit.dart';
import '../../features/users_admin/data/datasources/user_admin_remote_data_source.dart';
import '../../features/users_admin/data/repositories/user_admin_repository_impl.dart';
import '../../features/users_admin/domain/repositories/user_admin_repository.dart';
import '../../features/users_admin/domain/usecases/get_managed_users.dart';
import '../../features/users_admin/domain/usecases/set_user_role.dart';
import '../../features/users_admin/domain/usecases/update_managed_user.dart';
import '../../features/users_admin/presentation/cubit/users_admin_cubit.dart';
import '../../features/notifications/data/repositories/in_memory_notifications_repository.dart';
import '../../features/notifications/data/services/local_system_notifier.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/services/system_notifier.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/feedback/data/datasources/feedback_remote_data_source.dart';
import '../../features/feedback/data/datasources/supabase_feedback_remote_data_source.dart';
import '../../features/users_admin/data/datasources/supabase_user_admin_remote_data_source.dart';
import '../../features/feedback/domain/usecases/delete_feedback.dart';
import '../../features/feedback/domain/usecases/get_all_feedback.dart';
import '../../features/feedback/presentation/cubit/feedback_list_cubit.dart';
import '../../features/feedback/data/repositories/feedback_repository_impl.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import '../../features/feedback/domain/usecases/submit_feedback.dart';
import '../../features/feedback/presentation/cubit/feedback_cubit.dart';

class Injector {
  Injector._();
  static final Injector instance = Injector._();

  // ---- Data sources (استبدل الـ Mock هنا لما الداتابيز تجهز)
  late final CarRemoteDataSource _carRemote = _buildCarRemote();

  /// المصدر البعيد: Mock افتراضيًا. لما الـ Backend يجهز:
  ///   1) ضيف dio + crypto + flutter_secure_storage في pubspec
  ///   2) شغّل بـ --dart-define-from-file=env.json (USE_MOCK_DATA=false + API_BASE_URL + API_KEY)
  ///   3) خلاص: بيتبدّل لـ ApiCarRemoteDataSource + DioApiClient (Auth Interceptor) لوحده
  CarRemoteDataSource _buildCarRemote() {
    if (_useBackend) return SupabaseCarRemoteDataSource(_apiClient);
    AppConfig.assertSecureConfig(); // يرفض أي API_BASE_URL مش https
    // إعلانات المستخدمين المقبولة بتظهر في الرئيسية
    return MockCarRemoteDataSource(
      extraCars: () => AdsStore.instance.approvedUserCars,
      hiddenIds: () => AdsStore.instance.hiddenCatalogCarIds,
    );
  }
  final CarLocalDataSource _carLocal = InMemoryCarLocalDataSource();
  final SavedCarsLocalDataSource _favoritesLocal =
      InMemorySavedCarsLocalDataSource();
  final BookingsLocalDataSource _bookingsLocal =
      InMemoryBookingsLocalDataSource();

  // ---- Repositories (singletons: بيعيشوا طول عمر التطبيق)
  late final CarRepository carRepository =
      CarRepositoryImpl(remote: _carRemote, local: _carLocal);
  late final FavoritesRepository favoritesRepository =
      FavoritesRepositoryImpl(_favoritesLocal);
  late final BookingsRepository bookingsRepository = _useBackend
      ? SupabaseBookingsRepository(_apiClient)
      : BookingsRepositoryImpl(_bookingsLocal);

  // ---- التخزين الآمن (Keychain / Keystore) — بيحفظ التوكنز وبيانات الحساب بعد قفل التطبيق
  final SecureStorage _secureStorage = const FlutterSecureStorageImpl();

  // ---- المصادقة (Auto Login + Persistent Auth)
  // الـ Backend حقيقي لما USE_MOCK_DATA=false + API_BASE_URL، وإلا توكنز تجريبية.
  bool get _useBackend => AppConfig.useBackend;

  late final TokenStore tokenStore = TokenStore(_secureStorage);
  final SessionEvents _sessionEvents = SessionEvents();

  late final AuthRemoteDataSource _authRemote = _useBackend
      ? SupabaseAuthRemoteDataSource(DioApiClient.unauthenticated())
      : const MockAuthRemoteDataSource();

  /// كود التحقق من الإيميل أثناء التسجيل (Supabase OTP أو تجريبي)
  late final EmailVerificationService emailVerification = _useBackend
      ? SupabaseEmailVerification(DioApiClient.unauthenticated())
      : const MockEmailVerification();

  late final AuthRepositoryImpl _authRepositoryImpl = AuthRepositoryImpl(
    remote: _authRemote,
    tokens: tokenStore,
    events: _sessionEvents,
  );
  AuthRepository get authRepository => _authRepositoryImpl;

  /// العميل الشبكي المحمي: بيضيف Bearer ويجدد التوكن تلقائيًا عند 401.
  ApiClient get apiClient => _apiClient;

  late final ApiClient _apiClient = DioApiClient(
    tokens: tokenStore,
    refresher: _authRepositoryImpl,
    onSessionExpired: _sessionEvents.notifyExpired,
  );

  // ---- الحساب (بيانات المستخدم)
  late final AccountRepository accountRepository =
      AccountRepositoryImpl(_secureStorage);

  // ---- رأيك يهمنا / آراء العملاء (Mock في الذاكرة، أو POST/GET /feedback لما الـ Backend يجهز)
  late final FeedbackRemoteDataSource _feedbackRemote = _useBackend
      ? SupabaseFeedbackRemoteDataSource(_apiClient)
      : MockFeedbackRemoteDataSource();
  late final FeedbackRepository feedbackRepository =
      FeedbackRepositoryImpl(_feedbackRemote);

  // ---- إدارة المستخدمين (للمالك): Mock في الذاكرة، أو /admin/users لما الـ Backend يجهز
  late final UserAdminRemoteDataSource _userAdminRemote = _useBackend
      ? SupabaseUserAdminRemoteDataSource(_apiClient)
      : MockUserAdminRemoteDataSource();
  late final UserAdminRepository userAdminRepository =
      UserAdminRepositoryImpl(_userAdminRemote);

  // ---- الإشعارات (داخل التطبيق + إشعارات التليفون)
  late final NotificationsRepository notificationsRepository = _useBackend
      ? SupabaseNotificationsRepository(_apiClient)
      : InMemoryNotificationsRepository();

  /// إعلانات المستخدمين (رفع الصور + حفظ + مراجعة) على Supabase
  late final AdsRemote adsRemote = AdsRemote(_apiClient);
  final SystemNotifier systemNotifier = LocalSystemNotifier();

  // ---- Cubits (بيتبنوا مرة لكل شاشة رئيسية)
  AuthCubit createAuthCubit() => AuthCubit(
        checkAuthStatus: CheckAuthStatusUseCase(authRepository),
        logout: LogoutUseCase(authRepository),
        sessionExpired: authRepository.sessionExpired,
      );

  CarsCubit createCarsCubit() => CarsCubit(
        getCars: GetCars(carRepository),
        getBrandCounts: GetBrandCounts(carRepository),
      );

  FavoritesCubit createFavoritesCubit() => FavoritesCubit(
        getFavorites: GetFavorites(favoritesRepository),
        toggleFavorite: ToggleFavorite(favoritesRepository),
        clearFavorites: ClearFavorites(favoritesRepository),
      );

  BookingsCubit createBookingsCubit() => BookingsCubit(
        getBookings: GetBookings(bookingsRepository),
        bookCar: BookCar(bookingsRepository),
        clearBookings: ClearBookings(bookingsRepository),
        removeBooking: RemoveBooking(bookingsRepository),
      );

  AccountCubit createAccountCubit() => AccountCubit(
        getUserProfile: GetUserProfile(accountRepository),
        signOut: SignOut(accountRepository),
      );

  FeedbackCubit createFeedbackCubit() => FeedbackCubit(
        submitFeedback: SubmitFeedback(feedbackRepository),
        notifications: notificationsRepository,
      );

  NotificationsCubit createNotificationsCubit() => NotificationsCubit(
        repository: notificationsRepository,
        notifier: systemNotifier,
        account: accountRepository,
      );

  FeedbackListCubit createFeedbackListCubit() => FeedbackListCubit(
        getAllFeedback: GetAllFeedback(feedbackRepository),
        deleteFeedback: DeleteFeedback(feedbackRepository),
      );

  UsersAdminCubit createUsersAdminCubit() => UsersAdminCubit(
        getUsers: GetManagedUsers(userAdminRepository),
        updateUser: UpdateManagedUser(userAdminRepository),
        setRole: SetUserRole(userAdminRepository),
      );
}
