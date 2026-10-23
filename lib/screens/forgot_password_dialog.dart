import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/di/injection.dart';
import '../core/error/failure.dart';
import '../constants/theme_controller.dart';

/// يفتح نافذة "استعادة كلمة المرور".
/// بترجّع البريد الإلكتروني لو المستخدم ضغط "إرسال رمز التحقق" ونجح الطلب،
/// أو null لو ضغط "إلغاء".
Future<String?> showForgotPasswordDialog(
  BuildContext context, {
  String? initialEmail,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: ThemeController.barrierColor,
    builder: (_) => ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordDialog({super.key, this.initialEmail});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  static Color get _fieldFill => AppColors.tone(0xFFF6F8FB);
  static Color get _fieldBorder => AppColors.tone(0xFFCBD9EA);
  static Color get _iconBg => AppColors.tone(0xFFEFF5FF);
  static Color get _iconColor => AppColors.tone(0xFF0A5CD6);

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _loading = false;
  bool _submitted = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmail?.trim() ?? '';
    // نملّي الحقل بس لو اللي اتكتب في اللوجن بريد إلكتروني
    _emailController =
        TextEditingController(text: _emailRegex.hasMatch(initial) ? initial : '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!_emailRegex.hasMatch(input)) return 'أدخل بريد إلكتروني صحيح';
    return null;
  }

  Future<void> _send() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _apiError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();

      // بيتأكد إن الحساب موجود الأول، ولو مش موجود بيرمي رسالة "أنشئ حساب"
      await Injector.instance.emailVerification.sendResetCode(email);

      if (!mounted) return;
      Navigator.of(context).pop(email);
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'تعذّر إرسال الرمز، جرّب تاني');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
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
                    child: Icon(Icons.lock_reset,
                        color: _iconColor, size: 34),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'استعادة كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'أدخل بريدك الإلكتروني المسجل لإرسال رمز التحقق وإعادة تعيين كلمة المرور.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  'البريد الإلكتروني',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  validator: _validateEmail,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) {
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                  onFieldSubmitted: (_) => _send(),
                  style:
                      TextStyle(fontSize: 16, color: AppColors.title),
                  decoration: _inputDecoration(),
                ),

                if (_apiError != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBox(_apiError!),
                ],

                const SizedBox(height: 18),

                // Send button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.dark.withOpacity(0.85),
                      disabledForegroundColor: Colors.white70,
                      elevation: 5,
                      shadowColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
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
                                Icon(Icons.send_outlined, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'إرسال رمز التحقق',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Cancel
                TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.subtitle,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );

    return InputDecoration(
      hintText: 'email@domain.com',
      hintTextDirection: TextDirection.ltr,
      hintStyle: TextStyle(fontSize: 16, color: AppColors.hint),
      filled: true,
      fillColor: _fieldFill,
      errorMaxLines: 2,
      errorStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.error,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      enabledBorder: border(_fieldBorder),
      disabledBorder: border(_fieldBorder),
      focusedBorder: border(AppColors.navy, 1.6),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.6),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
