// Domain/Core: أخطاء "آمنة للمستخدم" — رسالة عربية بس، من غير أي تفاصيل تقنية
// (مفيش stack trace ولا شكل الداتابيز ولا رد السيرفر الخام).

abstract class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message; // عمدًا: مفيش تسريب
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'مفيش اتصال بالإنترنت، اتأكد من الشبكة وحاول تاني']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'الاتصال أخد وقت طويل، حاول مرة تانية']);
}

class InsecureConnectionFailure extends Failure {
  const InsecureConnectionFailure(
      [super.message = 'تعذّر إنشاء اتصال آمن بالسيرفر']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(
      [super.message = 'انتهت الجلسة، سجّل الدخول من جديد']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر المطلوب غير موجود']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'البيانات المدخلة غير صحيحة']);
}

class ServerFailure extends Failure {
  const ServerFailure(
      [super.message = 'في مشكلة مؤقتة في السيرفر، حاول بعد شوية']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'تعذّر قراءة البيانات المحفوظة']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
      [super.message = 'حصل خطأ أثناء تحميل السيارات، حاول مرة تانية']);
}
