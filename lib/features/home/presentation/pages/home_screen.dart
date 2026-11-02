// Presentation: الشاشة الرئيسية — الهيدر + التابات + شريط التنقل السفلي.
// هنا بس "تركيب" الشاشة؛ المنطق في الـ Cubits (features/cars/presentation/cubit).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/theme_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/push/notification_router.dart';
import '../../../../core/widgets/deferred_loader.dart';
import '../../../ads/presentation/pages/ads_management_page.dart' deferred as ads_admin show AdsManagementPage;
import '../../../bookings_admin/presentation/pages/bookings_management_page.dart' deferred as bookings_admin show BookingsManagementPage;
import '../../../feedback/presentation/pages/feedback_management_page.dart' deferred as feedback_admin show FeedbackManagementPage;
import '../../../notifications/presentation/pages/notifications_page.dart' deferred as notif_page show NotificationsPage;
import '../../../../screens/ads_store.dart';
import '../../../../screens/bookings_store.dart';
import '../../../../screens/my_ad.dart';
import '../../../../screens/my_ads_tab.dart' deferred as my_ads show MyAdsTab;
import '../../../../screens/sell_car_tab.dart' deferred as sell_car show SellCarTab;
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../account/presentation/pages/account_tab.dart' deferred as account_tab show AccountTab;
import '../../../cars/presentation/cubit/bookings_cubit.dart';
import '../../../cars/presentation/cubit/cars_cubit.dart';
import '../../../cars/presentation/cubit/cars_state.dart';
import '../../../cars/presentation/cubit/favorites_cubit.dart';
import '../../../cars/presentation/pages/bookings_tab.dart' deferred as book_tab show BookingsTab;
import '../../../cars/presentation/pages/favorites_tab.dart' deferred as fav_tab show FavoritesTab;
import '../../../cars/presentation/pages/car_details_screen.dart' deferred as car_details show CarDetailsScreen;
import '../../../cars/presentation/pages/home_tab.dart';
import '../../../cars/presentation/widgets/car_link_listener.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _bookingsTabIndex = 4;

  int _tab = 0;
  final Set<int> _loadedTabs = {0};

  // الإعلانات في مخزن مشترك (AdsStore) عشان الأدمن/المالك يديروها من "إدارة الإعلانات"
  final AdsStore _store = AdsStore.instance;

  /// إعلانات المستخدم الحالي فقط (من غير اللي اتباعت)
  List<MyAd> _myAds() {
    final p = _accountCubit.state.profile;
    final email = (p?.email ?? '').trim().toLowerCase();
    return _store.all
        .where((a) =>
    !a.isCatalog &&
        a.status != MyAdStatus.sold &&
        a.ownerEmail.trim().toLowerCase() == email)
        .toList();
  }

  // الـ Cubits عايشة طول عمر الشاشة الرئيسية => الداتا بتفضل محفوظة (In-Memory Cache)
  // ومبتتحمّلش تاني لما تتنقل بين التابات أو ترجع من شاشة التفاصيل.
  late final CarsCubit _carsCubit = Injector.instance.createCarsCubit()..load();
  late final FavoritesCubit _favoritesCubit =
  Injector.instance.createFavoritesCubit()..load();
  late final BookingsCubit _bookingsCubit =
  Injector.instance.createBookingsCubit()..load();
  late final AccountCubit _accountCubit =
  Injector.instance.createAccountCubit()..load();

  /// عملية ناجحة اتسجّلت: نشيل الحجز من "حجوزاتي" عند المشتري
  void _onBookingsAdmin() {
    if (!mounted) return;
    for (final b
    in BookingsAdminStore.instance.byStatus(ManagedBookingStatus.success)) {
      if (_bookingsCubit.state.cars.any((c) => c.id == b.car.id)) {
        _bookingsCubit.remove(b.car.id);
      }
    }
  }

  int _homeVer = 0;

  void _onStore() {
    if (!mounted) return;
    setState(() {});
    // إعلان اتقبل / اترفض / اتباع: نحدّث الصفحة الرئيسية
    if (_store.homeVersion != _homeVer) {
      _homeVer = _store.homeVersion;
      _carsCubit.refresh();
    }
  }

  StreamSubscription<CarsState>? _carsSub;
  Timer? _adsTimer;

  /// الضغط على "الرئيسية" وهي مفتوحة => تحديث + رجوع لأول القايمة
  final ValueNotifier<int> _homeReselect = ValueNotifier<int>(0);
  StreamSubscription<dynamic>? _notifSub;

  /// خطأ من عملية على السيرفر (رفع إعلان / قبول / حذف...): نعرضه للمستخدم
  /// الضغط على إشعار (من التليفون أو Push): حجز جديد -> إدارة الحجوزات،
  /// إعلان جديد -> إدارة الإعلانات، رأي جديد -> آراء العملاء، غير كده -> الإشعارات
  void _openForNotification(String? type) async {
    if (!mounted) return;
    switch (type) {
      case 'newBooking':
        await bookings_admin.loadLibrary();
        if (mounted) bookings_admin.BookingsManagementPage.open(context);
      case 'newAd':
        _store.loadFromServer(force: true);
        await ads_admin.loadLibrary();
        if (mounted) {
          ads_admin.AdsManagementPage.open(
            context,
            pending: true,
            carsCubit: _carsCubit,
            accountCubit: _accountCubit,
          );
        }
      case 'newFeedback':
        await feedback_admin.loadLibrary();
        if (mounted) {
          feedback_admin.FeedbackManagementPage.open(context, accountCubit: _accountCubit);
        }
      default:
        await notif_page.loadLibrary();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => notif_page.NotificationsPage()),
          );
        }
    }
  }

  void _onStoreError() {
    final msg = _store.lastError.value;
    if (!mounted || msg == null) return;
    _store.lastError.value = null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    _store.lastError.addListener(_onStoreError);
    NotificationRouter.instance.attach(_openForNotification);
    if (AppConfig.useBackend) {
      // إعلاناتي (أو كل الإعلانات للمالك/الأدمن) من السيرفر + تحديث دوري
      _store.loadFromServer();
      BookingsAdminStore.instance.loadFromServer();
      // الفحص الدوري خفيف
      _adsTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _store.loadFromServer();
        BookingsAdminStore.instance.loadFromServer();
      });
      // أي إشعار جديد (إعلان جديد / حجز / قبول...) => نحدّث فورًا
      _notifSub = Injector.instance.notificationsRepository.published.listen((_) {
        _store.loadFromServer();
        BookingsAdminStore.instance.loadFromServer();
      });
    }
    BookingsAdminStore.instance.addListener(_onBookingsAdmin);
    // أي سيارة بتظهر في الصفحة الرئيسية = "تم المراجعة" في إدارة الإعلانات
    _store.syncCatalog(_carsCubit.state.cars);
    _carsSub = _carsCubit.stream.listen((s) => _store.syncCatalog(s.cars));
  }

  @override
  void dispose() {
    _carsSub?.cancel();
    _adsTimer?.cancel();
    _homeReselect.dispose();
    _notifSub?.cancel();
    NotificationRouter.instance.detach();
    _store.lastError.removeListener(_onStoreError);
    _store.removeListener(_onStore);
    _store.clearForLogout(); // بيانات المستخدم ما تفضلش لمستخدم تاني
    BookingsAdminStore.instance.removeListener(_onBookingsAdmin);
    _carsCubit.close();
    _favoritesCubit.close();
    _bookingsCubit.close();
    _accountCubit.close();
    super.dispose();
  }

  /// بعد إرسال إعلان من "بيع سيارتك": بيتضاف في "إعلاناتي" ونروح للتاب ده
  void _publishAd(MyAd ad) {
    _store.add(ad);
    _loadedTabs.add(1);
    setState(() => _tab = 1);
  }

  /// "عرض وتعديل" (للإعلان وهو قيد المراجعة): نعرض كل التفاصيل والصور،
  /// ومن هناك زرار "تعديل الإعلان" بيفتح الفورم معبّي ببيانات الإعلان.
  void _openMyAd(MyAd ad) async {
    if (ad.status != MyAdStatus.pending) return;
    await car_details.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => car_details.CarDetailsScreen(
          car: ad.toCar(),
          viewOnly: true,
          onEdit: () => _editMyAd(ad),
        ),
      ),
    );
  }

  void _editMyAd(MyAd ad) async {
    if (!mounted) return;
    await sell_car.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeCtx) => MultiBlocProvider(
          providers: [
            BlocProvider<CarsCubit>.value(value: _carsCubit),
            BlocProvider<AccountCubit>.value(value: _accountCubit),
          ],
          child: Scaffold(
            backgroundColor: AppColors.pageBg,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.title),
            ),
            body: sell_car.SellCarTab(
              editing: ad,
              onPublished: (updated) {
                _store.replace(updated);
                Navigator.of(routeCtx).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _markSold(MyAd ad) {
    _store.markSold(ad.id);
    // اللي كان حاجز السيارة دي يتبلّغ إنها اتباعت
    BookingsAdminStore.instance.failActiveForCar(ad.carId, sold: true);
  }

  /// بعد تأكيد الحجز / طلب الشراء: ننقل لتاب حجوزاتي
  void _goToBookings() {
    _loadedTabs.add(_bookingsTabIndex);
    setState(() => _tab = _bookingsTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CarsCubit>.value(value: _carsCubit),
        BlocProvider<FavoritesCubit>.value(value: _favoritesCubit),
        BlocProvider<BookingsCubit>.value(value: _bookingsCubit),
        BlocProvider<AccountCubit>.value(value: _accountCubit),
      ],
      child: CarLinkListener(
        onBooked: _goToBookings,
        child: Scaffold(
          backgroundColor: AppColors.pageBg,
          // الهيدر جوه كل تاب عشان يتحرك مع الاسكرول
          body: AnimatedBuilder(
            animation: ThemeController.instance,
            builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: ThemeController.instance.isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: IndexedStack(
                index: _tab,
                children: [
                  HomeTab(
                    onBooked: _goToBookings,
                    reselectSignal: _homeReselect,
                  ),
                  _loadedTabs.contains(1)
                      ? DeferredWidget(
                          loadLibrary: my_ads.loadLibrary,
                          builder: () => BlocBuilder<AccountCubit, AccountState>(
                            builder: (context, _) => my_ads.MyAdsTab(
                              ads: _myAds(),
                              onBack: () {
                                _loadedTabs.add(0);
                                setState(() => _tab = 0);
                              },
                              onAddNew: () {
                                _loadedTabs.add(2);
                                setState(() => _tab = 2);
                              },
                              onSold: _markSold,
                              onOpen: _openMyAd,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  _loadedTabs.contains(2)
                      ? Column(
                          children: [
                            const AppTopBar(),
                            Expanded(
                              child: DeferredWidget(
                                loadLibrary: sell_car.loadLibrary,
                                builder: () => sell_car.SellCarTab(onPublished: _publishAd),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                  _loadedTabs.contains(3)
                      ? DeferredWidget(
                          loadLibrary: fav_tab.loadLibrary,
                          builder: () => fav_tab.FavoritesTab(onBooked: _goToBookings),
                        )
                      : const SizedBox.shrink(),
                  _loadedTabs.contains(4)
                      ? DeferredWidget(
                          loadLibrary: book_tab.loadLibrary,
                          builder: () => book_tab.BookingsTab(onBooked: _goToBookings),
                        )
                      : const SizedBox.shrink(),
                  _loadedTabs.contains(5)
                      ? DeferredWidget(
                          loadLibrary: account_tab.loadLibrary,
                          builder: () => account_tab.AccountTab(),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Builder(
            builder: (context) => AppBottomNav(
              current: _tab,
              favCount: context.watch<FavoritesCubit>().state.cars.length,
              adsCount: context.watch<AccountCubit>().state.profile == null
                  ? 0
                  : _myAds().length,
              bookingsCount: context.watch<BookingsCubit>().state.cars.length,
              onTap: (i) {
                if (i == 0 && _tab == 0) {
                  _homeReselect.value++; // نفس التاب: تحديث + أول القايمة
                } else {
                  _loadedTabs.add(i);
                  setState(() => _tab = i);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}