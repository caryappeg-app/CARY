// Presentation: صفحة "رأيك يهمنا" — الموضوع (شكوى / اقتراح / استفسار / تقييم)،
// وبعد اختياره بتظهر خانة التفاصيل، وزرار "إرسال" ثابت تحت.
// ملحوظة: ألوان AppColors بتتغير مع الوضع الداكن، فمفيش `const` على أي حاجة بتستخدمها.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/theme_controller.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/feedback_rules.dart';
import '../../domain/entities/feedback_subject.dart';
import '../cubit/feedback_cubit.dart';

/// النصوص والأيقونات الخاصة بكل موضوع (الـ Domain مبيعرفش عنها حاجة)
extension FeedbackSubjectUi on FeedbackSubject {
  String get label => switch (this) {
    FeedbackSubject.complaint => 'شكوى',
    FeedbackSubject.suggestion => 'اقتراح',
    FeedbackSubject.inquiry => 'استفسار',
    FeedbackSubject.rating => 'تقييم',
  };

  IconData get icon => switch (this) {
    FeedbackSubject.complaint => Icons.report_gmailerrorred_rounded,
    FeedbackSubject.suggestion => Icons.lightbulb_outline_rounded,
    FeedbackSubject.inquiry => Icons.help_outline_rounded,
    FeedbackSubject.rating => Icons.star_outline_rounded,
  };

  String get hint => switch (this) {
    FeedbackSubject.complaint => 'اكتب تفاصيل الشكوى...',
    FeedbackSubject.suggestion => 'اكتب اقتراحك...',
    FeedbackSubject.inquiry => 'اكتب استفسارك...',
    FeedbackSubject.rating => 'اكتب تقييمك وملاحظاتك...',
  };
}

class FeedbackPage extends StatefulWidget {
  final String senderName;
  final String senderEmail;
  final String senderPhone;

  const FeedbackPage({
    super.key,
    this.senderName = '',
    this.senderEmail = '',
    this.senderPhone = '',
  });

  /// بيفتح الصفحة مع Cubit جديد (الحالة بتتمسح كل مرة)
  static Future<void> open(
      BuildContext context, {
        String senderName = '',
        String senderEmail = '',
        String senderPhone = '',
      }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<FeedbackCubit>(
          create: (_) => Injector.instance.createFeedbackCubit(),
          child: FeedbackPage(
            senderName: senderName,
            senderEmail: senderEmail,
            senderPhone: senderPhone,
          ),
        ),
      ),
    );
  }

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: error ? AppColors.error : AppColors.dark,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeController.instance.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: SafeArea(
          child: BlocConsumer<FeedbackCubit, FeedbackState>(
            listener: (context, state) {
              if (state.status == FeedbackStatus.success) {
                _snack('تم إرسال رأيك بنجاح، شكرًا لك');
                Navigator.of(context).maybePop();
              } else if (state.status == FeedbackStatus.failure &&
                  state.error != null) {
                _snack(state.error!, error: true);
              }
            },
            builder: (context, state) {
              final cubit = context.read<FeedbackCubit>();
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  children: [
                    const _Header(),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel('الموضوع'),
                            const SizedBox(height: 10),
                            _SubjectPicker(
                              selected: state.subject,
                              onSelected: cubit.selectSubject,
                            ),
                            // خانة التفاصيل بتظهر بعد تحديد الموضوع
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: state.subject == null
                                  ? const SizedBox(width: double.infinity)
                                  : Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 22),
                                  const _SectionLabel('التفاصيل'),
                                  const SizedBox(height: 10),
                                  _DetailsField(
                                    controller: _details,
                                    hint: state.subject!.hint,
                                    enabled: !state.isSubmitting,
                                    onChanged: cubit.setDetails,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ---- زرار الإرسال ثابت تحت
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.fieldBorder),
                        ),
                      ),
                      child: _SendButton(
                        enabled: state.canSubmit,
                        loading: state.isSubmitting,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          cubit.submit(
                            senderName: widget.senderName,
                            senderEmail: widget.senderEmail,
                            senderPhone: widget.senderPhone,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Widgets
// =============================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppColors.surface,
            shape: CircleBorder(
              side: BorderSide(color: AppColors.fieldBorder),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.arrow_back_rounded,
                    color: AppColors.title, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'رأيك يهمنا',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.title,
      ),
    );
  }
}

/// اختيار الموضوع: 4 خيارات (اثنين في كل صف)
class _SubjectPicker extends StatelessWidget {
  final FeedbackSubject? selected;
  final ValueChanged<FeedbackSubject> onSelected;

  const _SubjectPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = FeedbackSubject.values;
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SubjectChip(
                  subject: items[i],
                  selected: selected == items[i],
                  onTap: () => onSelected(items[i]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SubjectChip(
                  subject: items[i + 1],
                  selected: selected == items[i + 1],
                  onTap: () => onSelected(items[i + 1]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final FeedbackSubject subject;
  final bool selected;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.title;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.fieldBorder,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subject.icon,
                size: 24, color: selected ? Colors.white : AppColors.blue),
            const SizedBox(width: 8),
            Text(
              subject.label,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _DetailsField({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.3]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: c, width: w),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      minLines: 6,
      maxLines: 10,
      maxLength: FeedbackRules.maxDetails,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: TextStyle(fontSize: 16, height: 1.6, color: AppColors.title),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15.5, color: AppColors.hint),
        counterStyle: TextStyle(fontSize: 12.5, color: AppColors.subtitle),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        border: border(AppColors.fieldBorder),
        enabledBorder: border(AppColors.fieldBorder),
        disabledBorder: border(AppColors.fieldBorder),
        focusedBorder: border(AppColors.blue, 1.6),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.fieldBorder,
          disabledForegroundColor: AppColors.hint,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: loading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: Colors.white),
        )
            : const Text(
          'إرسال',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}