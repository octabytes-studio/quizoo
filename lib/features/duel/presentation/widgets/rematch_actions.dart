import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_rematch_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-41's primary rematch control for a live duel (plan 017, Phase 11) —
/// one button whose face follows [DuelRematchCubit]'s handshake:
///
/// * idle → "Rematch" (asks),
/// * waiting → "Waiting for {name}…" (disabled),
/// * offered → "{name} wants a rematch!" over a pulsing "Accept rematch",
/// * starting → a spinner while the new duel opens,
/// * unavailable → "{name} has left" (disabled).
class RematchActions extends StatelessWidget {
  const RematchActions({required this.opponentName, super.key});

  /// The opponent as the result screen names them ("Guest 4821" for a
  /// guest).
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<DuelRematchCubit, DuelRematchState>(
      builder: (context, state) => switch (state) {
        RematchIdle() => ChunkyButton(
          label: l10n.duelResultRematch,
          onPressed: () => context.read<DuelRematchCubit>().request(),
        ),
        RematchWaiting() => ChunkyButton(
          label: l10n.duelRematchWaiting(opponentName),
          onPressed: null,
        ),
        RematchOffered() => _RematchOffer(opponentName: opponentName),
        RematchStarting() => const _RematchStartingIndicator(),
        RematchUnavailable() => ChunkyButton(
          label: l10n.duelRematchUnavailable(opponentName),
          onPressed: null,
        ),
      },
    );
  }
}

/// The opponent asked first: their ask above a gently pulsing accept button
/// (held still under reduced motion).
class _RematchOffer extends StatefulWidget {
  const _RematchOffer({required this.opponentName});

  final String opponentName;

  @override
  State<_RematchOffer> createState() => _RematchOfferState();
}

class _RematchOfferState extends State<_RematchOffer>
    with SingleTickerProviderStateMixin {
  /// How far the accept button swells at the top of each pulse.
  static const double _pulseScale = 1.04;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.tick,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.duelRematchOffered(widget.opponentName),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.copyWith(color: quizoo.tx),
        ),
        SizedBox(height: AppSpacing.sm.h),
        ScaleTransition(
          scale: Tween<double>(
            begin: 1,
            end: _pulseScale,
          ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: ChunkyButton.success(
            label: l10n.duelRematchAccept,
            onPressed: () => context.read<DuelRematchCubit>().accept(),
          ),
        ),
      ],
    );
  }
}

/// Both players asked; the new duel is opening.
class _RematchStartingIndicator extends StatelessWidget {
  const _RematchStartingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ChunkyButton.height.h + AppElevation.ledge.h,
      child: Center(
        child: SizedBox.square(
          dimension: 28.w,
          child: CircularProgressIndicator(
            color: context.quizoo.p,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}
