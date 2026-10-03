import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/subscription/domain/pro_benefit.dart';
import 'package:quizoo/core/subscription/pro_membership_line.dart';
import 'package:quizoo/features/subscription/presentation/bloc/paywall_cubit.dart';
import 'package:quizoo/features/subscription/presentation/widgets/paywall_hero.dart';
import 'package:quizoo/features/subscription/presentation/widgets/pro_benefit_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// What a member sees instead of the paywall (`/pro/membership`, plan 023).
///
/// Plan name, the right date line, a billing-issue notice when there is one,
/// the benefit list as a receipt, "Manage subscription" (the store's own
/// cancel/change page) and "Restore purchases". A free player who lands here
/// is redirected to the paywall from a listener — never from the builder
/// (CLAUDE.md §3).
class ProMembershipScreen extends StatelessWidget {
  const ProMembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Restore has one code path: the paywall's Cubit (plan 023, 4.6).
      create: (context) => PaywallCubit(context.read<SubscriptionRepository>()),
      child: const _MembershipView(),
    );
  }
}

class _MembershipView extends StatelessWidget {
  const _MembershipView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) =>
          previous.isPro != current.isPro && !current.isPro,
      listener: (context, state) => context.pushReplacement(AppRoutes.paywall),
      builder: (context, state) {
        final current = state;
        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.linear(AppGradients.washAngle, [
                AppColors.proWashTop,
                AppColors.proWashBottom,
              ]),
            ),
            child: SafeArea(
              child: switch (current) {
                SubscriptionPro() => _MemberBody(
                  membership: current.membership,
                  l10n: l10n,
                ),
                SubscriptionFree() => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _MemberBody extends StatelessWidget {
  const _MemberBody({required this.membership, required this.l10n});

  final ProMembership? membership;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateLine = proMembershipLineLabel(
      context,
      line: membershipLineOf(membership),
      expiresAt: membership?.expiresAt,
    );
    final isLifetime = membership?.plan == ProPlan.lifetime;
    final isGuest = context.select<SessionCubit, bool>(
      (cubit) => cubit.state.user == null,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.sm.h,
        AppSpacing.lg.w,
        AppSpacing.lg.h,
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
          ),
        ),
        const PaywallHero(),
        SizedBox(height: AppSpacing.lg.h),
        ProGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dateLine,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall!.copyWith(color: Colors.white),
              ),
              if (membership?.hasBillingIssue == true) ...[
                SizedBox(height: AppSpacing.base.h),
                _BillingIssueBanner(l10n: l10n),
              ],
              SizedBox(height: AppSpacing.base.h),
              for (final benefit in ProBenefit.values)
                ProBenefitRow(benefit: benefit, showGoldCheck: true),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        if (membership != null && !isLifetime) ...[
          ChunkyButton.secondary(
            label: l10n.proManageSubscription,
            onPressed: () => _manage(context),
          ),
          SizedBox(height: AppSpacing.sm.h),
        ],
        ChunkyButton.ghost(
          label: l10n.proRestore,
          onPressed: () => _restore(context),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Text(
          l10n.proRestoreHelper,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall!.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        if (isGuest) ...[
          SizedBox(height: AppSpacing.base.h),
          ChunkyButton.line(
            label: l10n.proSaveToAccount,
            onPressed: () => context.push(AppRoutes.saveProgress),
          ),
        ],
      ],
    );
  }

  /// Sends the player to the store's own management page. The store owns
  /// cancellation — the SDK's `managementURL` when it has one, its account
  /// page otherwise — so "cancel" is never code the app runs itself.
  Future<void> _manage(BuildContext context) async {
    final opened = await context.read<SubscriptionCubit>().openManagement();
    if (!context.mounted || opened) return;

    AppSnackbar.show(
      context,
      title: AppLocalizations.of(context).proManageFailed,
      intent: SnackbarIntent.error,
      emoji: '⚠️',
    );
  }

  /// Restore has one code path: the paywall Cubit (plan 023, 4.6).
  ///
  /// A member tapping this is usually recovering a second device, so the
  /// outcome **must** be said out loud — before this, a successful restore
  /// emitted `PaywallPurchased` and the screen did nothing at all, which
  /// reads as a dead button.
  Future<void> _restore(BuildContext context) async {
    final cubit = context.read<PaywallCubit>();
    await cubit.restore();
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final state = cubit.state;
    cubit.clearNotice();

    // `restore()` reports its outcome as the Cubit's state; the notice is
    // only set for the two failures, and `PaywallPurchased` means it worked.
    final (
      String? message,
      SnackbarIntent intent,
      String emoji,
    ) = switch (state) {
      PaywallPurchased() => (
        l10n.proRestoreSuccess,
        SnackbarIntent.success,
        '✅',
      ),
      PaywallReady(notice: PaywallNotice.nothingToRestore) => (
        l10n.proNoticeNothingToRestore,
        SnackbarIntent.info,
        '↩️',
      ),
      PaywallReady(notice: PaywallNotice.failed) => (
        l10n.proNoticeFailed,
        SnackbarIntent.error,
        '⚠️',
      ),
      // A cancelled store sheet, or a restore still in flight — say nothing.
      _ => (null, SnackbarIntent.info, ''),
    };
    if (message == null) return;

    AppSnackbar.show(context, title: message, intent: intent, emoji: emoji);
  }
}

class _BillingIssueBanner extends StatelessWidget {
  const _BillingIssueBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.proGoldTo.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.proGoldFrom),
      ),
      child: Text(
        l10n.proMembershipBillingIssue,
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(color: Colors.white),
      ),
    );
  }
}
