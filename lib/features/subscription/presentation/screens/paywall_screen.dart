import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/subscription/pro_offer.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/subscription/domain/pro_benefit.dart';
import 'package:quizoo/features/subscription/presentation/bloc/paywall_cubit.dart';
import 'package:quizoo/features/subscription/presentation/widgets/paywall_hero.dart';
import 'package:quizoo/features/subscription/presentation/widgets/paywall_legal_footer.dart';
import 'package:quizoo/features/subscription/presentation/widgets/pro_benefit_row.dart';
import 'package:quizoo/features/subscription/presentation/widgets/pro_plan_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The Quizoo Pro paywall (`/pro`, plan 023).
///
/// One scrollable screen with a pinned purchase area: the benefits scroll,
/// the plans and the CTA stay put, so "Continue" is never below the fold.
/// The whole surface uses the fixed grape-to-night wash in both themes, like
/// the arena and the Topic Mastered screen — there is no dark-mode twin.
///
/// Layout per the plan's wireframe. At `Breakpoints.tablet` the content is
/// centred at `Breakpoints.maxContentWidth` rather than stretched.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, this.source = PaywallSource.direct});

  /// Where this visit came from — a routing argument only today.
  final PaywallSource source;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PaywallCubit(context.read<SubscriptionRepository>())..load(),
      child: const _PaywallView(),
    );
  }
}

class _PaywallView extends StatefulWidget {
  const _PaywallView();

  @override
  State<_PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<_PaywallView> {
  /// Plan 023, 4.3: a member who reaches `/pro` (a deep link, a stale card)
  /// belongs on the membership screen, not a paywall. Checked after the
  /// first frame, and re-checked whenever the entitlement flips to Pro
  /// while this screen is open — never from the builder (CLAUDE.md §3).
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfPro());
  }

  void _redirectIfPro() {
    if (!mounted) return;
    if (!context.read<SubscriptionCubit>().state.isPro) return;
    context.pushReplacement(AppRoutes.proMembership);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) => current.isPro && !previous.isPro,
      listener: (context, state) => _redirectIfPro(),
      child: Scaffold(
        // The Pro wash: identical in light and dark, like the mastery wash.
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.linear(AppGradients.washAngle, [
              AppColors.proWashTop,
              AppColors.proWashBottom,
            ]),
          ),
          child: SafeArea(
            child: BlocConsumer<PaywallCubit, PaywallState>(
              listener: _handleState,
              builder: (context, state) {
                return Column(
                  children: [
                    _CloseBar(l10n: l10n),
                    Expanded(child: _Body(state: state)),
                    _PurchaseArea(state: state),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Navigation and one-shot notices live in the listener, never the builder
  /// (CLAUDE.md §3).
  void _handleState(BuildContext context, PaywallState state) {
    final l10n = AppLocalizations.of(context);
    if (state is PaywallPurchased) {
      context.pushReplacement(AppRoutes.proWelcome);
      return;
    }
    if (state is PaywallReady && state.notice != null) {
      switch (state.notice!) {
        case PaywallNotice.failed:
          AppSnackbar.show(
            context,
            title: l10n.proNoticeFailed,
            intent: SnackbarIntent.error,
            emoji: '⚠️',
            actionLabel: l10n.proNoticeRetry,
            onAction: () => context.read<PaywallCubit>().purchase(),
          );
        case PaywallNotice.pending:
          AppSnackbar.show(
            context,
            title: l10n.proNoticePending,
            intent: SnackbarIntent.info,
            emoji: '⏳',
          );
        case PaywallNotice.nothingToRestore:
          AppSnackbar.show(
            context,
            title: l10n.proNoticeNothingToRestore,
            intent: SnackbarIntent.info,
            emoji: '↩️',
          );
      }
      context.read<PaywallCubit>().clearNotice();
    }
  }
}

class _CloseBar extends StatelessWidget {
  const _CloseBar({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: IconButton(
          onPressed: () => context.pop(),
          tooltip: l10n.proNotNow,
          icon: const Icon(Icons.close_rounded),
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final PaywallState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < Breakpoints.tablet;
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: narrow
                ? constraints.maxWidth
                : Breakpoints.maxContentWidth,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.w,
              AppSpacing.sm.h,
              AppSpacing.lg.w,
              AppSpacing.lg.h,
            ),
            children: [
              const PaywallHero(),
              SizedBox(height: AppSpacing.xl.h),
              const ProGlassCard(child: _BenefitList()),
            ],
          ),
        );
        return narrow
            ? content
            : Center(child: SingleChildScrollView(child: content));
      },
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final benefit in ProBenefit.values)
          ProBenefitRow(benefit: benefit),
      ],
    );
  }
}

class _PurchaseArea extends StatelessWidget {
  const _PurchaseArea({required this.state});

  final PaywallState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A public field cannot be promoted, so the switch runs on a local.
    final current = state;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.base.h,
        AppSpacing.lg.w,
        AppSpacing.base.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.proWashBottom,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet.r),
        ),
      ),
      child: switch (current) {
        PaywallLoading() => const _SkeletonPlans(),
        PaywallUnavailable() => _Unavailable(error: current.error),
        PaywallReady() => _Ready(state: current, l10n: l10n),
        PaywallPurchased() => const SizedBox.shrink(),
      },
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state, required this.l10n});

  final PaywallReady state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaywallCubit>();
    final selected = state.selectedOffer;
    final trialDays = selected?.trialDays;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final offer in state.offers) ...[
          ProPlanCard(
            offer: offer,
            isSelected: offer.plan == state.selected,
            savingsPercent: offer.plan == ProPlan.yearly
                ? state.yearlySavingsPercent
                : null,
            onTap: state.isBusy ? () {} : () => cubit.select(offer.plan),
          ),
          SizedBox(height: AppSpacing.sm.h),
        ],
        SizedBox(height: AppSpacing.xs.h),
        ChunkyButton.gold(
          label: state.isBusy
              ? l10n.proWorking
              : (trialDays != null
                    ? l10n.proStartTrial(trialDays)
                    : l10n.proContinue),
          onPressed: state.isBusy ? () {} : () => cubit.purchase(),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Text(
          _disclosure(l10n, selected),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        PaywallLegalFooter(onRestore: () => cubit.restore()),
      ],
    );
  }

  /// The store-required price/period disclosure, chosen by the selected plan
  /// and worded with the store's own price string.
  String _disclosure(AppLocalizations l10n, ProOffer? offer) {
    if (offer == null) return l10n.proDisclosureLifetime;
    return switch (offer.plan) {
      ProPlan.monthly => l10n.proDisclosureMonthly(offer.priceLabel),
      ProPlan.yearly => l10n.proDisclosureYearly(offer.priceLabel),
      ProPlan.lifetime => l10n.proDisclosureLifetime,
    };
  }
}

class _SkeletonPlans extends StatelessWidget {
  const _SkeletonPlans();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 64.h,
            decoration: BoxDecoration(
              color: AppColors.proCard,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              border: Border.all(color: AppColors.proCardBorder),
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
        ],
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.proUnavailableTitle,
          textAlign: TextAlign.center,
          style: textTheme.titleSmall!.copyWith(color: Colors.white),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          l10n.proUnavailableBody,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall!.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: AppSpacing.base.h),
        ChunkyButton.secondary(
          label: l10n.proTryAgain,
          onPressed: () => context.read<PaywallCubit>().load(),
        ),
        SizedBox(height: AppSpacing.sm.h),
        PaywallLegalFooter(
          onRestore: () => context.read<PaywallCubit>().restore(),
        ),
      ],
    );
  }
}
