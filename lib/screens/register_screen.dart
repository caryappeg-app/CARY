import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/theme_controller.dart';
import '../core/di/injection.dart';
import '../core/error/failure.dart';
import '../features/account/domain/entities/user_profile.dart';
import 'otp_verification_dialog.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static Color get _blue => AppColors.tone(0xFF0A5CD6);
  static Color get _success => AppColors.tone(0xFF16A34A);
  static Color get _cardBg => AppColors.tone(0xFFF8FAFC);
  static Color get _cardBorder => AppColors.tone(0xFFE2E8F0);
  static TextStyle get _inputStyle =>
      TextStyle(fontSize: 16, height: 1.5, color: AppColors.title);

  static final _arabicNameRegex = RegExp(r'^[\u0621-\u064A ]+$');
  static final _phoneRegex = RegExp(r'^01[0125]\d{8}$');
  static final _emailRegex =
  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState<String>>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _sendingCode = false;
  bool _emailVerified = false;
  bool _emailLive = false; // validation مباشر لحقل الإيميل بعد أول محاولة
  bool _submitted = false; // validation الفورم يبدأ بعد أول محاولة إنشاء
  String? _apiError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validateName(String? value) {
    final v = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v.isEmpty) return 'يرجى إدخال الاسم بالكامل';
    if (!_arabicNameRegex.hasMatch(v)) {
      return 'الاسم لازم يكون بالعربي وحروف فقط';
    }
    if (v.split(' ').length < 2) return 'اكتب الاسم الأول والأخير على الأقل';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'يرجى إدخال رقم الهاتف';
    if (!_phoneRegex.hasMatch(v)) {
      return 'أدخل رقم موبايل مصري صحيح (11 رقم يبدأ بـ 01)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!_emailRegex.hasMatch(v)) return 'أدخل بريد إلكتروني صحيح';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'يرجى إدخال كلمة المرور';
    if (v.length < 6) return 'كلمة المرور لازم تكون 6 خانات على الأقل';
    final hasLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) {
      return 'كلمة المرور لازم تحتوي على أحرف وأرقام';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (v != _passController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _clearApiError([String? _]) {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _sendCode() async {
    if (_sendingCode || _loading || _emailVerified) return;
    FocusScope.of(context).unfocus();

    if (!_emailLive) setState(() => _emailLive = true);
    if (!(_emailKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() {
      _sendingCode = true;
      _apiError = null;
    });

    try {
      await Injector.instance.emailVerification.sendCode(email);
      if (!mounted) return;

      final result = await showOtpVerificationDialog(context, email: email);
      if (!mounted) return;

      if (result == OtpDialogResult.verified) {
        setState(() => _emailVerified = true);
      } else if (result == OtpDialogResult.changeEmail) {
        _emailFocus.requestFocus();
      }
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'تعذّر إرسال الرمز، جرّب تاني');
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _register() async {
    if (_loading || _sendingCode) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitted = true;
      _apiError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!_emailVerified) {
      setState(() => _apiError =
      'لازم تتحقق من بريدك الإلكتروني الأول عن طريق زر "إرسال الرمز"');
      return;
    }

    setState(() => _loading = true);
    try {
      final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      final phone = _phoneController.text;
      final email = _emailController.text.trim();

      // Supabase: بعد التحقق من الإيميل بيحدد كلمة السر وبيكمّل الاسم والهاتف
      // (الدور user دايمًا). في وضع التجربة بيعمل تأخير وهمي بس.
      await Injector.instance.emailVerification.completeSignUp(
        email: email,
        fullName: name,
        phone: phone,
        password: _passController.text,
      );
      // ملاحظة أمنية: ممنوع طباعة بيانات المستخدم (اسم / هاتف / إيميل / كلمة سر)
      // حتى في debugPrint — الـ logs بتتجمع على أجهزة التطوير وأدوات التتبع.
      await Injector.instance.accountRepository.saveRegistration(
        UserProfile(fullName: name, email: email, phone: phone),
      );
      // يظهر الحساب الجديد في "إدارة المستخدمين" عند المالك
      await Injector.instance.userAdminRepository.trackRegistration(
        fullName: name,
        email: email,
        phone: phone,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'تم إنشاء حسابك بنجاح، سجّل الدخول للمتابعة',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.navy,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      Navigator.of(context).maybePop();
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'حصلت مشكلة أثناء إنشاء الحساب، جرّب تاني');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 18),
                      const _Logo(),
                      const SizedBox(height: 18),
                      const _Header(),
                      const SizedBox(height: 26),

                      // الاسم
                      const _LabelRow(
                        label: 'الاسم بالكامل (باللغة العربية فقط)',
                      ),
                      const SizedBox(height: 10),
                      _buildNameField(),
                      const SizedBox(height: 18),

                      // الهاتف
                      const _LabelRow(
                        label: 'رقم الهاتف (أرقام إنجليزية فقط)',
                        note: '11 رقماً',
                      ),
                      const SizedBox(height: 10),
                      _buildPhoneField(),
                      const SizedBox(height: 18),

                      // الإيميل + التحقق
                      _buildEmailCard(),
                      const SizedBox(height: 18),

                      // كلمة المرور
                      const _LabelRow(
                        label: 'كلمة المرور',
                        note: '6 خانات فأكثر',
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(),
                      const SizedBox(height: 18),

                      // تأكيد كلمة المرور
                      const _LabelRow(label: 'تأكيد كلمة المرور'),
                      const SizedBox(height: 10),
                      _buildConfirmField(),

                      if (_apiError != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(_apiError!),
                      ],

                      const SizedBox(height: 24),
                      _buildRegisterButton(),
                      const SizedBox(height: 18),
                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocus,
      validator: _validateName,
      enabled: !_loading,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\u0621-\u064A ]')),
        LengthLimitingTextInputFormatter(60),
      ],
      onChanged: _clearApiError,
      onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
      style: _inputStyle,
      decoration: _decoration(
        hint: 'Full Name',
        // في RTL الـ suffix بيظهر على الشمال زي التصميم
        suffix: Icon(Icons.person_outline,
            color: AppColors.icon, size: 26),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocus,
      validator: _validatePhone,
      enabled: !_loading,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        _EnglishDigitsFormatter(),
        LengthLimitingTextInputFormatter(11),
      ],
      onChanged: _clearApiError,
      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
      style: _inputStyle,
      decoration: _decoration(
        hint: 'Phone number',
        hintLtr: true,
        // في RTL الـ prefix بيظهر على اليمين زي التصميم
        prefix: Icon(Icons.smartphone_outlined,
            color: AppColors.icon, size: 26),
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LabelRow(
            label: 'البريد الإلكتروني والتحقق',
            note: 'email@domain.com',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أول عنصر في RTL بيبقى على اليمين
              Expanded(
                child: TextFormField(
                  key: _emailKey,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  validator: _validateEmail,
                  autovalidateMode: _emailLive
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  enabled: !_loading && !_sendingCode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) {
                    // لو غيّر الإيميل بعد التحقق لازم يتحقق تاني
                    if (_emailVerified || _apiError != null) {
                      setState(() {
                        _emailVerified = false;
                        _apiError = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) => _sendCode(),
                  style: _inputStyle,
                  decoration: _decoration(
                    hint: 'Email',
                    hintLtr: true,
                    radius: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildSendCodeButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendCodeButton() {
    final verified = _emailVerified;
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: (_loading || _sendingCode || verified) ? null : _sendCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: verified ? _success : AppColors.checkbox,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          verified ? _success : AppColors.checkbox.withOpacity(0.85),
          disabledForegroundColor: verified ? Colors.white : Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _sendingCode
              ? const SizedBox(
            key: ValueKey('loading'),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
              : Row(
            key: ValueKey(verified ? 'done' : 'send'),
            mainAxisSize: MainAxisSize.min,
            children: [
              // في RTL أول عنصر بيبقى على اليمين
              Icon(
                verified
                    ? Icons.check_circle_outline
                    : Icons.send_outlined,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                verified ? 'تم التحقق' : 'إرسال الرمز',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passController,
      focusNode: _passFocus,
      validator: _validatePassword,
      enabled: !_loading,
      obscureText: _obscurePass,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      autofillHints: const [AutofillHints.newPassword],
      autocorrect: false,
      enableSuggestions: false,
      onChanged: _clearApiError,
      onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
      style: _inputStyle,
      decoration: _decoration(
        hint: '••••••••',
        hintLtr: true,
        suffix: _eyeButton(
          obscure: _obscurePass,
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ),
      ),
    );
  }

  Widget _buildConfirmField() {
    return TextFormField(
      controller: _confirmController,
      focusNode: _confirmFocus,
      validator: _validateConfirm,
      enabled: !_loading,
      obscureText: _obscureConfirm,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      autofillHints: const [AutofillHints.newPassword],
      autocorrect: false,
      enableSuggestions: false,
      onChanged: _clearApiError,
      onFieldSubmitted: (_) => _register(),
      style: _inputStyle,
      decoration: _decoration(
        hint: '••••••••',
        hintLtr: true,
        suffix: _eyeButton(
          obscure: _obscureConfirm,
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
    );
  }

  Widget _eyeButton({required bool obscure, required VoidCallback onPressed}) {
    return IconButton(
      tooltip: obscure ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.icon,
        size: 28,
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    bool hintLtr = false,
    Widget? prefix,
    Widget? suffix,
    double radius = 22,
  }) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      hintText: hint,
      hintTextDirection: hintLtr ? TextDirection.ltr : TextDirection.rtl,
      hintStyle:
      TextStyle(fontSize: 16, height: 1.5, color: AppColors.hint),
      filled: true,
      fillColor: AppColors.surface,
      errorMaxLines: 3,
      errorStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.error,
      ),
      prefixIcon: prefix == null
          ? null
          : Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: prefix,
      ),
      suffixIcon: suffix == null
          ? null
          : Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: suffix,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: border(AppColors.border),
      disabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.navy, 1.6),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.6),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: (_loading || _sendingCode) ? null : _register,
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
              : const Row(
            key: ValueKey('label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              // في RTL أول عنصر بيبقى على اليمين
              Icon(Icons.person_add_alt_1_outlined, size: 26),
              SizedBox(width: 10),
              Text(
                'إنشاء الحساب الآن',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟',
          style: TextStyle(fontSize: 15, color: AppColors.subtitle),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: _blue,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'تسجيل الدخول',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Small widgets
// =============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // أول عنصر في RTL بيبقى على اليمين (زر الرجوع)
        Tooltip(
          message: 'رجوع',
          child: Material(
            color: AppColors.surface,
            elevation: 1,
            shadowColor: Colors.black26,
            shape: CircleBorder(
              side: BorderSide(color: AppColors.tone(0xFFE5E9F0)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_forward,
                    color: AppColors.title, size: 22),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            'منصة CARY المعتمدة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.icon,
            ),
          ),
        ),
        // نفس عرض زر الرجوع عشان العنوان يفضل في النص
        const SizedBox(width: 44),
      ],
    );
  }
}

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
          'إنشاء حساب جديد في CARY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.title,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'انضم الآن لسوق الشفافية والسيارات المفحوصة',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.subtitle),
        ),
      ],
    );
  }
}

/// العنوان على اليمين، وملاحظة صغيرة رمادية على الشمال
class _LabelRow extends StatelessWidget {
  final String label;
  final String? note;
  const _LabelRow({required this.label, this.note});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
        ),
        if (note != null)
          Text(
            note!,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 13, color: AppColors.hint),
          ),
      ],
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

/// يقبل الأرقام بس، ويحوّل الأرقام العربية (٠١٢...) لإنجليزية
class _EnglishDigitsFormatter extends TextInputFormatter {
  static const _arabic = '٠١٢٣٤٥٦٧٨٩';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    for (var i = 0; i < _arabic.length; i++) {
      text = text.replaceAll(_arabic[i], '$i');
    }
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}