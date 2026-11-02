import 'package:cary_app/screens/reset_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';
import '../core/di/injection.dart';
import '../core/error/failure.dart';
import '../features/account/domain/entities/user_profile.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import 'forgot_password_dialog.dart';
import '../features/home/presentation/pages/home_screen.dart';
import 'otp_verification_dialog.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  final _idFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;
  bool _submitted = false; // الـ validation يبدأ بعد أول محاولة دخول
  String? _apiError;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    _idFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// يحوّل الأرقام العربية/الهندية (٠١٢...) لأرقام إنجليزية
  static String _normalizeDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var out = input;
    for (var i = 0; i < arabic.length; i++) {
      out = out.replaceAll(arabic[i], '$i');
    }
    return out;
  }

  static final _phoneRegex = RegExp(r'^01[0125]\d{8}$');
  static final _emailRegex =
  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  String? _validateIdentifier(String? value) {
    final input = _normalizeDigits(value?.trim() ?? '');
    if (input.isEmpty) return 'يرجى إدخال رقم الهاتف أو البريد الإلكتروني';
    if (!_phoneRegex.hasMatch(input) && !_emailRegex.hasMatch(input)) {
      return 'أدخل رقم موبايل مصري صحيح (11 رقم) أو بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
    // 6 خانات على الأقل (حروف أو أرقام أو رموز)
    if (value.length < 6) return 'كلمة المرور لازم تكون 6 خانات على الأقل';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _login() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitted = true;
      _apiError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final identifier = _normalizeDigits(_idController.text.trim());

      // تسجيل الدخول: بيحفظ Access/Refresh Token في التخزين الآمن (TokenStore)
      // وبيفضل المستخدم داخل عند فتح التطبيق تاني (Auto Login) لو "تذكرني" مفعّل.
      final authCubit = context.read<AuthCubit>();
      await Injector.instance.authRepository.signIn(
        identifier: identifier,
        password: _passController.text,
        rememberMe: _remember,
      );
      // ملاحظة أمنية: ممنوع طباعة بيانات الدخول (هاتف / إيميل / كلمة سر) في الـ logs.
      // TODO: بدّل السطر ده بحفظ بيانات المستخدم اللي راجعة من الـ API
      // (الاسم الكامل + الإيميل + رقم الهاتف)
      await Injector.instance.accountRepository.signIn(identifier);
      // لو المالك عدّل بيانات الحساب أو حالته (مالك / أدمن / مستخدم) من "إدارة المستخدمين"
      // بنطبّقها هنا (في وضع الـ Mock؛ مع الـ Backend البروفايل بيرجع من السيرفر).
      final managed =
          await Injector.instance.userAdminRepository.findByIdentifier(identifier);
      if (managed != null) {
        await Injector.instance.accountRepository.applyProfile(UserProfile(
          fullName: managed.fullName,
          email: managed.email,
          phone: managed.phone,
          role: managed.role,
        ));
      }
      authCubit.markAuthenticated();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'حصلت مشكلة أثناء تسجيل الدخول، جرّب تاني');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    FocusScope.of(context).unfocus();

    // 1) إدخال الإيميل  ->  2) رمز التحقق  ->  3) كلمة المرور الجديدة
    // "تغيير البريد" بيرجّع المستخدم لخطوة 1
    var email = await showForgotPasswordDialog(
      context,
      initialEmail: _idController.text,
    );

    while (email != null && mounted) {
      final result = await showOtpVerificationDialog(
        context,
        email: email,
        purpose: OtpPurpose.resetPassword,
      );
      if (!mounted) return;

      if (result == OtpDialogResult.changeEmail) {
        email = await showForgotPasswordDialog(context, initialEmail: email);
        continue;
      }

      if (result == OtpDialogResult.verified) {
        final done = await showResetPasswordDialog(context, email: email);
        if (done == true && mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Text(
                  'تم تعيين كلمة المرور بنجاح، سجّل الدخول من جديد',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.navy,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          // نفرّغ كلمة المرور ونحط الإيميل في حقل الدخول
          _passController.clear();
          _idController.text = email;
        }
      }
      break;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 28),
                        const _Header(),
                        const SizedBox(height: 20),

                        const _FieldLabel('رقم الهاتف أو البريد الإلكتروني'),
                        const SizedBox(height: 10),
                        _buildIdField(),
                        const SizedBox(height: 22),

                        const _FieldLabel('كلمة المرور'),
                        const SizedBox(height: 8),
                        _buildPasswordField(),
                        const SizedBox(height: 14),

                        _buildRememberRow(),

                        if (_apiError != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(_apiError!),
                        ],

                        const SizedBox(height: 22),
                        _buildLoginButton(),
                        const SizedBox(height: 22),
                        const _OrDivider(),
                        const SizedBox(height: 22),
                        _buildRegisterButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdField() {
    return TextFormField(
      controller: _idController,
      focusNode: _idFocus,
      validator: _validateIdentifier,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      autocorrect: false,
      enableSuggestions: false,
      enabled: !_loading,
      onChanged: (_) {
        if (_apiError != null) setState(() => _apiError = null);
      },
      onFieldSubmitted: (_) => _passFocus.requestFocus(),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: AppColors.title),
      decoration: _decoration(
        hint: 'Email or phone number',
        icon: Icon(Icons.contact_mail_outlined,
            color: AppColors.icon, size: 28),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passController,
      focusNode: _passFocus,
      validator: _validatePassword,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.password],
      autocorrect: false,
      enableSuggestions: false,
      enabled: !_loading,
      onChanged: (_) {
        if (_apiError != null) setState(() => _apiError = null);
      },
      onFieldSubmitted: (_) => _login(),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: AppColors.title),
      decoration: _decoration(
        hint: 'Enter password',
        icon: IconButton(
          tooltip: _obscure ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.icon,
            size: 28,
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({required String hint, required Widget icon}) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 16, color: AppColors.hint),
      hintTextDirection: TextDirection.ltr,
      errorMaxLines: 3,
      errorStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.error,
      ),
      // في RTL الـ suffix بيظهر على الشمال زي التصميم
      suffixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: icon,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      enabledBorder: border(AppColors.border),
      disabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.navy, 1.6),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.6),
    );
  }

  Widget _buildRememberRow() {
    return Row(
      children: [
        // أول عنصر في RTL بيبقى على اليمين
        TextButton(
          onPressed: _loading ? null : _forgotPassword,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.navy,
          ),
          child: const Text(
            'نسيت كلمة المرور؟',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _loading ? null : () => setState(() => _remember = !_remember),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _remember,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _remember = v ?? false),
                    activeColor: AppColors.checkbox,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'تذكرني على هذا الجهاز',
                  style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.dark.withOpacity(0.85),
          disabledForegroundColor: Colors.white70,
          elevation: 6,
          shadowColor: Colors.black38,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _loading
              ? const SizedBox(
            key: ValueKey('loading'),
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: Colors.white,
            ),
          )
              : const Text(
            'تسجيل الدخول',
            key: ValueKey('label'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: _loading
            ? null
            : () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.title,
          side: BorderSide(color: AppColors.dark, width: 1.2),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: const Text(
          'إنشاء حساب جديد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// =============================================================================
// Small widgets
// =============================================================================

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      // من غير مربع ولا إطار: اللوجو مدمج مباشرة في خلفية الشاشة
      child: SizedBox(
        width: 150,
        height: 110,
        child: Image.asset(
          ThemeController.logoAsset,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car_filled_outlined,
                  color: AppColors.navy, size: 36),
              const SizedBox(height: 2),
              Text(
                'CARY',
                style: GoogleFonts.montserrat(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'أهلاً بيك في CARY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'سوق الشفافية والثقة لسيارات صعيد مصر',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.subtitle),
        ),
        SizedBox(height: 6),
        Text(
          'سجّل الدخول عشان تكمل',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.subtitle),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.title,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.errorText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'مستخدم جديد؟',
            style: TextStyle(fontSize: 14, color: AppColors.hint),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}