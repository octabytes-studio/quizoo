import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/subscription/revenuecat_config.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Restore · Terms · Privacy, at the foot of the paywall (plan 023).
///
/// Both stores require a Terms of Use and a Privacy Policy link on a
/// subscription screen, and Apple requires Restore Purchases to exist — so
/// all three are always present, not conditional on anything.
class PaywallLegalFooter extends StatelessWidget {
  const PaywallLegalFooter({required this.onRestore, super.key});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: context.quizoo.tx3,
      decoration: TextDecoration.underline,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md.w,
      runSpacing: AppSpacing.xs.h,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRestore,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs.w),
            child: Text(l10n.proRestore, style: style),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openExternal(context, RevenueCatConfig.termsUrl),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs.w),
            child: Text(l10n.proTerms, style: style),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openExternal(context, RevenueCatConfig.privacyUrl),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs.w),
            child: Text(l10n.proPrivacy, style: style),
          ),
        ),
      ],
    );
  }

  /// Best-effort: a dead link must not crash a purchase screen, so the
  /// launch failure is swallowed and the player simply stays put.
  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
