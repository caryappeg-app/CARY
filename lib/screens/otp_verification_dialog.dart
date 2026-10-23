import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../core/di/injection.dart';
import '../core/error/failure.dart';
import '../constants/theme_controller.dart';

enum OtpDialogResult { verified, changeEmail }

/// الرمز ده لإنشاء حساب ولا لاستعادة كلمة المرور (بيحدد الإرسال عند "إعادة الإرسال")
enum OtpPurpose { signUp, resetPassword }

/// يفتح نافذة "التحقق من رمز التأكيد".
/// بترجّع:
///  - [OtpDialogResult.verified] لو الرمز اتأكد
///  - [OtpDialogResult.changeEmail] لو المستخدم ضغط "تغيير البريد"
///  - null لو النافذة اتقفلت
Future<OtpDialogResult?> showOtpVerificationDialog(
  BuildContext context, {
  required String email,
  OtpPurpose purpose = OtpPurpose.signUp,
}) {
  return showDialog<OtpDialogResult>(
    context: context,
    barrierColor: ThemeController.barrierColor,
    builder: (_) => OtpVerificationDialog(email: email, purpose: purpose),
  );
}

class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  const OtpVerificationDialog({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.signUp,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  static Color get _blue => AppColors.tone(0xFF0A5CD6);
  static Color get _iconBg => AppColors.tone(0xFFEFF5FF);
  static Color get _infoBg => AppColors.tone(0xFFEFF5FF);
  static Color get _infoBorder => AppColors.tone(0xFFC7DBF5);
  static int get _codeLength => Injector.instance.emailVerification.codeLength;
  static const _resendSeconds = 50;

  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _seconds = _resendSeconds;
  bool _loading = false;
  String? _error;
  String? _info;

  // يعزل الإيميل عشان يفضل LTR جوه النص العربي
  String get _emailIsolated => '\u2066${widget.email}\u2069';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_loading) return;
    final code = _codeController.text;
    if (code.length != _codeLength) {
      setState(() {
        _info = null;
        _error = 'أدخل رمز التحقق المكون من $_codeLength أرقام';
      });
      _focusNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      await Injector.instance.emailVerification.verifyCode(widget.email, code);

      if (!mounted) return;
      Navigator.of(context).pop(OtpDialogResult.verified);
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'الرمز غير صحيح أو منتهي، جرّب تاني');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_loading || _seconds > 0) return;
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      final svc = Injector.instance.emailVerification;
      if (widget.purpose == OtpPurpose.resetPassword) {
        await svc.sendResetCode(widget.email, resend: true);
      } else {
        await svc.sendCode(widget.email, resend: true);
      }
      if (!mounted) return;
      _codeController.clear();
      _startTimer();
      setState(() => _info = 'تم إعادة إرسال الرمز');
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر إعادة الإرسال، جرّب تاني');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.mark_email_read_outlined,
                      color: _blue, size: 34),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'التحقق من رمز التأكيد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'تم إرسال رمز مكون من $_codeLength أرقام إلى ($_emailIsolated).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 18),

              // Info box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _infoBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _infoBorder),
                ),
                child: Text(
                  'تم إرسال رمز التحقق إلى بريدك الإلكتروني ($_emailIsolated)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Text(
                'رمز التحقق ($_codeLength أرقام)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 10),

              _buildCodeField(),

              if (_error != null) ...[
                const SizedBox(height: 10),
                _StatusBox(text: _error!, isError: true),
              ] else if (_info != null) ...[
                const SizedBox(height: 10),
                _StatusBox(text: _info!, isError: false),
              ],

              const SizedBox(height: 16),
              _buildVerifyButton(),
              const SizedBox(height: 10),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField() {
    OutlineInputBorder border(Color c, [double w = 1.3]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextField(
      controller: _codeController,
      focusNode: _focusNode,
      autofocus: true,
      enabled: !_loading,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        _DigitsFormatter(),
        LengthLimitingTextInputFormatter(_codeLength),
      ],
      onChanged: (_) {
        if (_error != null || _info != null) {
          setState(() {
            _error = null;
            _info = null;
          });
        }
      },
      onSubmitted: (_) => _verify(),
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: _codeLength > 6 ? 8 : 16,
        color: AppColors.title,
      ),
      decoration: InputDecoration(
        hintText: '•' * _codeLength,
        hintStyle: TextStyle(
          fontSize: 22,
          letterSpacing: _codeLength > 6 ? 8 : 16,
          color: AppColors.hint,
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 24),
        enabledBorder: border(AppColors.tone(0xFFCBD9EA)),
        disabledBorder: border(AppColors.tone(0xFFCBD9EA)),
        focusedBorder: border(AppColors.tone(0xFF1E5AA8), 1.6),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _loading ? null : _verify,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _blue.withOpacity(0.85),
          disabledForegroundColor: Colors.white70,
          elevation: 5,
          shadowColor: _blue.withOpacity(0.4),
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
                    Icon(Icons.verified_outlined, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'التحقق والمتابعة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final canResend = _seconds == 0;

    return Row(
      children: [
        // يمين: إعادة الإرسال
        canResend
            ? TextButton(
                onPressed: _loading ? null : _resend,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'إعادة إرسال الرمز',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'إعادة الإرسال بعد (${_seconds}ث)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tone(0xFF94A3B8),
                  ),
                ),
              ),
        const Spacer(),
        // شمال: تغيير البريد
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.of(context).pop(OtpDialogResult.changeEmail),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.subtitle,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'تغيير البريد',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// يقبل الأرقام بس، ويحوّل الأرقام العربية (٠١٢...) لإنجليزية
class _DigitsFormatter extends TextInputFormatter {
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

class _StatusBox extends StatelessWidget {
  final String text;
  final bool isError;
  const _StatusBox({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final bg = isError ? AppColors.errorBg : AppColors.tone(0xFFDCFCE7);
    final border = isError ? AppColors.errorBorder : AppColors.tone(0xFF86EFAC);
    final fg = isError ? AppColors.errorText : AppColors.tone(0xFF166534);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    final iconColor = isError ? AppColors.error : AppColors.tone(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
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
