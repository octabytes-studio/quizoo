import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-54 — the notification-permission pre-prompt.
///
/// Fires "after the third completed level, never on first launch" per the
/// bible — real cross-session trigger tracking is out of scope (plan 001's
/// Assumption 7), so this is reached only through a debug row in Settings for
/// review purposes. The time picker is a real `showTimePicker` — genuinely
/// easy to make real since it is a built-in Flutter widget (plan 004,
/// Research findings).
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 30);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _turnOn(BuildContext context) {
    Navigator.of(context).maybePop();
    AppSnackbar.show(
      context,
      title: AppLocalizations.of(
        context,
      ).notificationPermissionOnTitle(_reminderTime.format(context)),
      intent: SnackbarIntent.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: quizoo.ov,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w + 2.w),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                22.w,
                AppSpacing.xl.h,
                22.w,
                AppSpacing.lg.h,
              ),
              decoration: BoxDecoration(
                color: quizoo.s1,
                borderRadius: AppRadius.dialogAll,
                boxShadow: quizoo.shadowLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 66.w,
                      height: 66.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: quizoo.p.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(
                          AppRadius.dialogIcon.r,
                        ),
                      ),
                      child: Text('🔔', style: AppTypography.glyph(33.sp)),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Text(
                    l10n.notificationPermissionTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    l10n.notificationPermissionBody,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                  SizedBox(height: AppSpacing.base.h),
                  GestureDetector(
                    onTap: _pickTime,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.base.w,
                        vertical: AppSpacing.sm.h + 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: quizoo.s3,
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.notificationPermissionTimeLabel,
                              style: textTheme.bodyLarge!.copyWith(
                                fontSize: 13.5.sp,
                              ),
                            ),
                          ),
                          Text(
                            _reminderTime.format(context),
                            style: textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: quizoo.g,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.base.h + 2.h),
                  ChunkyButton(
                    label: l10n.notificationPermissionTurnOn,
                    onPressed: () => _turnOn(context),
                  ),
                  SizedBox(height: 9.h),
                  ChunkyButton.line(
                    label: l10n.notificationPermissionNotNow,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
