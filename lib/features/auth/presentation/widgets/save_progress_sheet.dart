import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/auth/presentation/widgets/vendor_sign_in_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-24 — the save-progress sheet. **The one conversion moment in the app.**
///
/// Four of the bible's rules for it are load-bearing:
///
/// * It quotes the player's **own live numbers** back at them, not a generic
///   pitch.
/// * "Not now" is **always plain text** — never disabled, never hidden, never
///   styled to lose.
/// * It appears only after a *completed* level, at most once, and never after
///   a failure. That gating lives in `AuthRepository`, not here.
/// * The vendor buttons follow each vendor's required chrome exactly.
///
/// Sign-in is mocked end to end: no token, no network, no vendor SDK.
class SaveProgressSheet extends StatelessWidget {
  const SaveProgressSheet({
    required this.score,
    required this.levelNumber,
    required this.percentThrough,
    required this.dayStreak,
    super.key,
  });

  /// The score the player would lose, which is the headline.
  final int score;
  final int levelNumber;
  final int percentThrough;
  final int dayStreak;

  /// The sheet as reached from the result chain, with that run's numbers.
  factory SaveProgressSheet.forRun({
    required int score,
    required int levelNumber,
  }) => SaveProgressSheet(
    score: score,
    levelNumber: levelNumber,
    percentThrough: 82,
    dayStreak: MockPlayer.dayStreak,
  );

  Future<void> _signIn(BuildContext context, AuthProvider provider) async {
    final session = context.read<SessionCubit>();
    final l10n = AppLocalizations.of(context);

    if (provider == AuthProvider.email) {
      // Email is the only route with a profile still to fill in.
      await session.startEmailSignIn();
      if (!context.mounted) return;
      context.pop();
      await context.push(AppRoutes.profileCreation);
      return;
    }

    await session.signInWithVendor(provider);
    if (!context.mounted) return;
    context.pop();
    AppSnackbar.show(
      context,
      title: l10n.saveProgressSaved,
      intent: SnackbarIntent.success,
      emoji: '✅',
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        final isBusy = session is SessionAuthenticating;

        return AppBottomSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  MockPlayer.avatarEmoji,
                  style: AppTypography.glyph(44.sp),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                l10n.saveProgressTitle(AppFormat.number(score, localeName)),
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge,
              ),
              SizedBox(height: 5.h),
              Text(
                l10n.saveProgressBody(percentThrough, levelNumber, dayStreak),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              SizedBox(height: AppSpacing.base.h),
              VendorSignInButton(
                provider: AuthProvider.google,
                label: l10n.saveProgressGoogle,
                onPressed: isBusy
                    ? null
                    : () => _signIn(context, AuthProvider.google),
              ),
              SizedBox(height: 9.h),
              VendorSignInButton(
                provider: AuthProvider.apple,
                label: l10n.saveProgressApple,
                onPressed: isBusy
                    ? null
                    : () => _signIn(context, AuthProvider.apple),
              ),
              SizedBox(height: 9.h),
              VendorSignInButton(
                provider: AuthProvider.email,
                label: l10n.saveProgressEmail,
                onPressed: isBusy
                    ? null
                    : () => _signIn(context, AuthProvider.email),
              ),
              SizedBox(height: AppSpacing.md.h),
              // Plain text, always. Declining is a first-class choice here.
              Center(
                child: GestureDetector(
                  onTap: context.pop,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Text(
                        l10n.saveProgressNotNow,
                        style: textTheme.bodyMedium!.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: quizoo.tx3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                l10n.saveProgressTerms,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(height: 1.5),
              ),
              SizedBox(height: AppSpacing.sm.h),
            ],
          ),
        );
      },
    );
  }
}

/// What S-24 needs to quote the player's own numbers back at them.
///
/// Passed through the route's `extra`, so the result screen can push the
/// sheet's path without importing the sheet itself.
class SaveProgressArgs {
  const SaveProgressArgs({required this.score, required this.levelNumber});

  final int score;
  final int levelNumber;
}
