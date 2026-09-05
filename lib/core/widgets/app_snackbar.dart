import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The four snackbar intents (§06).
enum SnackbarIntent {
  /// Mint. "Progress saved".
  success,

  /// Raspberry. "You're offline".
  error,

  /// Primary-text fill. "Daily challenge is live".
  info,

  /// Lemon. "Not enough coins".
  warning,
}

/// The app's snackbar.
///
/// Sits 16px in from the safe area **above the tab bar** — which it gets for
/// free by going through [ScaffoldMessenger] with floating behaviour rather
/// than a hand-rolled overlay. Auto-dismisses at 3.2s, or 5s when it carries
/// an action, and never stacks: showing one replaces whatever is on screen,
/// exactly as the bible specifies.
class AppSnackbar extends StatelessWidget {
  const AppSnackbar({
    required this.title,
    required this.intent,
    super.key,
    this.message,
    this.emoji,
  });

  final String title;

  /// The smaller second line.
  final String? message;

  /// Leading glyph. Defaults to the intent's own emoji.
  final String? emoji;

  final SnackbarIntent intent;

  /// Shows [title]/[message] as a snackbar, replacing any current one.
  ///
  /// Returns the controller so a caller can await dismissal if it needs to.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String title,
    required SnackbarIntent intent,
    String? message,
    String? emoji,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // "Never stack — a new one replaces the old."
    messenger.hideCurrentSnackBar();

    final hasAction = actionLabel != null && onAction != null;

    return messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.all(AppSpacing.base.w),
        behavior: SnackBarBehavior.floating,
        duration: hasAction ? AppMotion.snackbarWithAction : AppMotion.snackbar,
        content: _AppSnackbarSurface(
          title: title,
          message: message,
          emoji: emoji,
          intent: intent,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AppSnackbarSurface(
      title: title,
      message: message,
      emoji: emoji,
      intent: intent,
    );
  }
}

/// The snackbar's painted surface, shared by [AppSnackbar.show] and by the
/// widget form used in galleries and tests.
class _AppSnackbarSurface extends StatelessWidget {
  const _AppSnackbarSurface({
    required this.title,
    required this.intent,
    this.message,
    this.emoji,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? emoji;
  final SnackbarIntent intent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    final (
      Color background,
      Color foreground,
      String defaultEmoji,
    ) = switch (intent) {
      SnackbarIntent.success => (quizoo.ok, Colors.white, '✅'),
      SnackbarIntent.error => (quizoo.bad, Colors.white, '📡'),
      SnackbarIntent.info => (quizoo.tx, quizoo.s1, '🔔'),
      SnackbarIntent.warning => (quizoo.gold, AppColors.onGold, '⚠️'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.snackbar.r),
        boxShadow: quizoo.shadowLarge,
      ),
      child: Row(
        children: [
          Text(emoji ?? defaultEmoji, style: AppTypography.glyph(19.sp)),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
                if (message != null)
                  Text(
                    message!,
                    style: textTheme.bodyLarge!.copyWith(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: foreground.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(width: AppSpacing.md.w),
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionLabel!,
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                  decoration: TextDecoration.underline,
                  decorationColor: foreground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
