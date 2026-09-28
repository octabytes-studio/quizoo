import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/presentation/bloc/composer_state.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_countdown_ring.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_clock_label.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The arena's sticky bottom bar (plan 017, S-38): "＋ Create challenge", the
/// creation cool-off, the viewer's own open challenge, a guest's sign-in
/// prompt, or "You're in a duel". Safe-area aware.
class ChallengeComposerBar extends StatelessWidget {
  const ChallengeComposerBar({
    required this.composer,
    required this.now,
    required this.config,
    required this.onCreate,
    required this.onSignIn,
    super.key,
    this.isBusy = false,
  });

  final ComposerState composer;

  /// Server time.
  final DateTime now;

  /// For the ring totals (TTL and cool-off).
  final DuelConfig config;

  /// Opens the topic picker for a new challenge.
  final VoidCallback onCreate;

  /// A guest's way to an account.
  final VoidCallback onSignIn;

  /// A create/cancel is in flight.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = l10n.localeName;

    final Widget content = switch (composer) {
      ComposerCreate() => ChunkyButton(
        label: l10n.duelComposerCreate,
        icon: const Text('＋'),
        onPressed: isBusy ? null : onCreate,
      ),
      ComposerSignIn() => ChunkyButton.secondary(
        label: l10n.duelComposerSignIn,
        icon: const Text('🔑'),
        onPressed: onSignIn,
      ),
      ComposerCooldown(:final until) => _StatusPlate(
        remaining: _left(until),
        total: Duration(seconds: config.cooldownSeconds),
        label: l10n.duelComposerCooldown(_left(until).clockLabel(localeName)),
      ),
      ComposerOwnOpen(:final challenge) => _StatusPlate(
        remaining: _left(challenge.expiresAt),
        total: Duration(seconds: config.challengeTtlSeconds),
        label: l10n.duelComposerOpen(
          challenge.topic.name,
          _left(challenge.expiresAt).clockLabel(localeName),
        ),
      ),
      ComposerInDuel() => _StatusPlate(label: '⚔️ ${l10n.duelComposerInDuel}'),
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenMargin.w,
          AppSpacing.md.h,
          AppSpacing.screenMargin.w,
          AppSpacing.md.h,
        ),
        child: content,
      ),
    );
  }

  Duration _left(DateTime until) {
    final left = until.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// A non-interactive pill in the composer's slot, with an optional ring.
class _StatusPlate extends StatelessWidget {
  const _StatusPlate({required this.label, this.remaining, this.total});

  final String label;
  final Duration? remaining;
  final Duration? total;

  static const double ringDiameter = 22;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;
    final left = remaining;

    return Container(
      constraints: BoxConstraints(minHeight: ChunkyButton.height.h),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      decoration: BoxDecoration(
        color: arena.chrome,
        borderRadius: BorderRadius.circular(AppRadius.button.r),
        border: Border.all(color: arena.questionCardBorder),
      ),
      child: Row(
        children: [
          if (left != null) ...[
            ChallengeCountdownRing(
              remaining: left,
              total: total ?? left,
              diameter: ringDiameter,
              showLabel: false,
              trackColor: arena.questionCardBorder,
              labelStyle: textTheme.labelMedium!.copyWith(
                color: arena.onArena,
                fontFeatures: AppTypography.tabular,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: arena.onArena,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
