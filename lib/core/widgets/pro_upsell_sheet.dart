import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The small "this is a Pro perk" sheet (plan 023).
///
/// One emoji, one title, one sentence, one button — deliberately thin. The
/// design bible's anti-pillar is "no dark-pattern purchase prompts", so this
/// never auto-opens, never stacks, and always has a quiet "Not now" that
/// simply dismisses. Nothing in `core/` imports `features/subscription/`;
/// the sheet reaches the paywall only through [AppRoutes.paywall].
class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet({
    required this.emoji,
    required this.title,
    required this.message,
    required this.source,
    super.key,
  });

  final String emoji;
  final String title;
  final String message;

  /// Where the paywall is being opened from, so the plan can later learn
  /// which entry point converts.
  final PaywallSource source;

  /// Presents the sheet and resolves when it is dismissed.
  static Future<void> show(
    BuildContext context, {
    required String emoji,
    required String title,
    required String message,
    required PaywallSource source,
  }) {
    return AppBottomSheet.show<void>(
      context,
      builder: (_) => ProUpsellSheet(
        emoji: emoji,
        title: title,
        message: message,
        source: source,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge!.copyWith(color: quizoo.tx),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(color: quizoo.tx2),
          ),
          SizedBox(height: AppSpacing.lg.h),
          ChunkyButton.gold(
            label: l10n.proSeeQuizooPro,
            onPressed: () {
              final nav = Navigator.of(context, rootNavigator: true);
              final router = GoRouter.of(context);
              nav.pop();
              router.push(AppRoutes.paywall, extra: source);
            },
          ),
          SizedBox(height: AppSpacing.sm.h),
          ChunkyButton.ghost(
            label: l10n.proNotNow,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }
}
