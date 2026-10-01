import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_cubit.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/widgets/inline_ad_view.dart';

/// The shared host behind every banner and native ad widget.
///
/// Renders [placeholder] — nothing, by default — unless [AdsCubit] says
/// [placement] is on. Otherwise it owns one [InlineAdCubit] for as long as it
/// is mounted and lays the ad out through [frameBuilder], which each ad
/// widget uses to draw its own chrome.
///
/// **Layout stability** is the point of [keepsSpaceOnFailure]: an anchored
/// banner keeps its reserved height even when no ad arrives, so nothing above
/// it ever moves; an in-content slot reserves its height while loading and
/// folds away only if the load fails.
class InlineAdSlot extends StatelessWidget {
  const InlineAdSlot({
    required this.placement,
    required this.requestBuilder,
    required this.keepsSpaceOnFailure,
    required this.frameBuilder,
    super.key,
    this.placeholder = const SizedBox.shrink(),
  });

  final AdPlacement placement;

  /// Builds the request once the slot knows how much room it has.
  final InlineAdRequest Function(
    BuildContext context,
    BoxConstraints constraints,
  )
  requestBuilder;

  final bool keepsSpaceOnFailure;

  /// Wraps the ad — or the empty box reserving its space — in the slot's
  /// chrome.
  final Widget Function(BuildContext context, Widget ad) frameBuilder;

  /// What the slot renders while it has nothing to frame.
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select<AdsCubit, bool>(
      (cubit) => cubit.isPlacementEnabled(placement),
    );
    if (!isEnabled) return placeholder;

    // A theme switch gives the slot a new Cubit, so a native ad is requested
    // again in the right colours.
    final brightness = Theme.of(context).brightness;

    return LayoutBuilder(
      builder: (context, constraints) => BlocProvider<InlineAdCubit>(
        key: ValueKey<Brightness>(brightness),
        create: (context) {
          final request = requestBuilder(context, constraints);
          return InlineAdCubit(
            context.read<InlineAdService>(),
            initialReservedHeight: request.fixedHeight ?? 0,
          )..load(request);
        },
        child: _InlineAdSlotBody(
          keepsSpaceOnFailure: keepsSpaceOnFailure,
          frameBuilder: frameBuilder,
          placeholder: placeholder,
        ),
      ),
    );
  }
}

class _InlineAdSlotBody extends StatefulWidget {
  const _InlineAdSlotBody({
    required this.keepsSpaceOnFailure,
    required this.frameBuilder,
    required this.placeholder,
  });

  final bool keepsSpaceOnFailure;
  final Widget Function(BuildContext context, Widget ad) frameBuilder;
  final Widget placeholder;

  @override
  State<_InlineAdSlotBody> createState() => _InlineAdSlotBodyState();
}

/// A `State` only for the lifecycle listener — ephemeral plumbing with no
/// business meaning (CLAUDE.md §3): a slot on a long-lived tab swaps out an
/// expired ad when the app comes back to the foreground.
class _InlineAdSlotBodyState extends State<_InlineAdSlotBody> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<InlineAdCubit>().refreshIfStale(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Widget _reserved(BuildContext context, double height) => height > 0
      ? widget.frameBuilder(context, SizedBox(height: height))
      : widget.placeholder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InlineAdCubit, InlineAdState>(
      builder: (context, state) {
        final child = switch (state) {
          InlineAdLoading(:final reservedHeight) => _reserved(
            context,
            reservedHeight,
          ),
          InlineAdLoaded(:final ad) => widget.frameBuilder(
            context,
            InlineAdView(ad: ad),
          ),
          InlineAdUnavailable(:final reservedHeight) => _reserved(
            context,
            widget.keepsSpaceOnFailure ? reservedHeight : 0,
          ),
        };
        if (widget.keepsSpaceOnFailure) return child;
        return AnimatedSize(
          duration: AppMotion.durationOf(context, AppMotion.slide),
          curve: AppMotion.slideCurve,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
    );
  }
}
