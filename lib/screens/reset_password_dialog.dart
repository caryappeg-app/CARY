import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/di/injection.dart';
import '../core/error/failure.dart';
import '../constants/theme_controller.dart';

/// يفتح نافذة "تعيين كلمة المرور الجديدة".
/// بترجّع true لو كلمة المرور اتغيرت بنجاح، أو null لو اتقفلت.
Future<bool?> showResetPasswordDialog(
  BuildContext context, {
  required String email,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: ThemeController.barrierColor,
    builder: (_) => ResetPasswordDialog(email: email),
  );
}

class ResetPasswordDialog extends StatefulWidget {
  final String email;
  const ResetPasswordDialog({super.key, required this.email});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  static Color get _iconBg => AppColors.tone(0xFFEFF5FF);
  static Color get _iconColor => AppColors.tone(0xFF0A5CD6);
  static Color get _fieldFill => AppColors.tone(0xFFF8FAFC);
  static Color get _fieldBorder => AppColors.tone(0xFFD5DEE9);

  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  bool _submitted = false;
  String? _apiError;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'يرجى إدخال كلمة المرور الجديدة';
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

  Future<void> _save() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _apiError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await Injector.instance.emailVerification.resetPassword(
        email: widget.email,
        password: _passController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'تعذّر حفظ كلمة المرور، جرّب تاني');
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
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _iconBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.vpn_key_outlined,
                        color: _iconColor, size: 32),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'تعيين كلمة المرور الجديدة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'أدخل كلمة المرور الجديدة المكونة من 6 خانات مع أحرف وأرقام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 22),

                const _Label('كلمة المرور الجديدة'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passController,
                  validator: _validatePassword,
                  enabled: !_loading,
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) {
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                  onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                  style:
                      TextStyle(fontSize: 16, color: AppColors.title),
                  decoration: _decoration(
                    suffix: IconButton(
                      tooltip:
                          _obscure ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
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
                ),
                const SizedBox(height: 20),

                const _Label('تأكيد كلمة المرور الجديدة'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  validator: _validateConfirm,
                  enabled: !_loading,
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) {
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                  onFieldSubmitted: (_) => _save(),
                  style:
                      TextStyle(fontSize: 16, color: AppColors.title),
                  decoration: _decoration(),
                ),

                if (_apiError != null) ...[
                  const SizedBox(height: 14),
                  _ErrorBox(_apiError!),
                ],

                const SizedBox(height: 22),
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.dark.withOpacity(0.85),
                      disabledForegroundColor: Colors.white70,
                      elevation: 5,
                      shadowColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
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
                                Icon(Icons.lock_outline, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'حفظ وتعيين كلمة المرور',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: c, width: w),
        );

    return InputDecoration(
      hintText: '••••••••',
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
      suffixIcon: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: suffix,
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      enabledBorder: border(_fieldBorder),
      disabledBorder: border(_fieldBorder),
      focusedBorder: border(AppColors.tone(0xFF1E5AA8), 1.6),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.6),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.title,
      ),
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
