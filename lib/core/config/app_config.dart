// Core: إعدادات التطبيق من متغيرات البيئة (مفيش أي URL أو مفتاح مكتوب في الكود).
//
// التشغيل:
//   flutter run --dart-define-from-file=env.json
//   flutter build apk --dart-define-from-file=env.json
// (شوف env.example.json — وحط env.json في .gitignore)
//
// ملاحظة أمنية: القيم دي بتتحط وقت البناء. ما تحطش هنا أسرار السيرفر (service_role)؛
// المفتاح العام (anon) بس، وأي سر حقيقي مكانه الـ Backend.
class AppConfig {
  AppConfig._();

  /// عنوان الـ API (لازم https)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://qjlwtitcwsqnhcfrxdcv.supabase.co',
  );

  /// المفتاح العام للـ Backend (anon / publishable key)
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'sb_publishable_5LROCXppE2KzzBEztpYYew_ZeJvueOs',
  );

  /// رقم واتساب الدعم (محلي أو دولي). ممكن يتغير من غير تعديل كود:
  ///   --dart-define=SUPPORT_WHATSAPP=01XXXXXXXXX
  static const String supportWhatsapp =
      String.fromEnvironment('SUPPORT_WHATSAPP', defaultValue: '01201082852');

  /// true = استخدم الداتا التجريبية (false = Supabase الحقيقي)
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

  /// بصمات SHA-256 لشهادة السيرفر (Certificate Pinning) مفصولة بفاصلة
  static const String _pins = String.fromEnvironment('PINNED_CERT_SHA256');

  static List<String> get pinnedCertSha256 => _pins
      .split(',')
      .map((e) => e.replaceAll(':', '').trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  /// أساس رابط المشاركة (https). غيّره لدومين Cloudflare Pages بتاعك:
  ///   --dart-define=SHARE_LINK_BASE=https://cary.cary-egcom.workers.dev
  static const String shareLinkBase = String.fromEnvironment(
      'SHARE_LINK_BASE', defaultValue: 'https://cary.cary-egcom.workers.dev');

  static bool get hasBackend => apiBaseUrl.isNotEmpty;

  /// رابط الـ Cloudflare Worker لرفع صور الإعلانات على R2 (فاضي = Supabase Storage)
  static const String adsWorkerUrl = String.fromEnvironment(
    'ADS_WORKER_URL',
    defaultValue: 'https://cary-ads-api.cary-app-eg.workers.dev',
  );

  /// طول كود التحقق اللي Supabase بيبعته (Authentication > Providers > Email > Email OTP Length)
  static const int otpLength = int.fromEnvironment('OTP_LENGTH', defaultValue: 8);

  /// true = اشتغل على Supabase الحقيقي (USE_MOCK_DATA=false + API_BASE_URL)
  static bool get useBackend => !useMockData && hasBackend;

  /// بيرفض أي عنوان مش HTTPS (بيتنادى قبل إنشاء الـ HTTP client)
  static void assertSecureConfig() {
    if (hasBackend && !apiBaseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL لازم يبدأ بـ https://');
    }
  }
}

