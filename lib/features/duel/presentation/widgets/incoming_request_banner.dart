import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_clock_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// "🐯 Danish M. wants to duel!" — the request at the head of the viewer's
/// own challenge queue, with the 5-second window synced to the server
/// (plan 017, S-38). Slides down over the feed when one is presented and
/// away when it is answered, lapses or is withdrawn.
class IncomingRequestBanner extends StatelessWidget {
  const IncomingRequestBanner({
    required this.request,
    required this.now,
    required this.window,
    required this.onAccept,
    required this.onDecline,
    super.key,
    this.topicName = '',
    this.isBusy = false,
  });

  /// Null when nothing is presented — the banner slides away.
  final IncomingJoinRequest? request;

  /// Server time.
  final DateTime now;

  /// The decision window (`joinWindowSeconds`).
  final Duration window;

  /// The challenge's topic, for the requester's "Football Lv 4".
  final String topicName;

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// An answer is already in flight.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final current = request;
    return AnimatedSwitcher(
      duration: AppMotion.durationOf(context, AppMotion.slide),
      switchInCurve: AppMotion.curveOf(context, AppMotion.slideCurve),
      switchOutCurve: AppMotion.curveOf(context, AppMotion.slideCurve),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: AlignmentDirectional.topCenter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: current == null
          ? const SizedBox(width: double.infinity)
          : _IncomingPlate(
              key: ValueKey(current.requestId),
              request: current,
              now: now,
              window: window,
              topicName: topicName,
              onAccept: isBusy ? null : onAccept,
              onDecline: isBusy ? null : onDecline,
            ),
    );
  }
}

class _IncomingPlate extends StatelessWidget {
  const _IncomingPlate({
    required this.request,
    required this.now,
    required this.window,
    required this.topicName,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final IncomingJoinRequest request;
  final DateTime now;
  final Duration window;
  final String topicName;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  static const double barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final requester = request.requester;

    final left = request.expiresAt.difference(now);
    final remaining = left.isNegative ? Duration.zero : left;
    final fraction = window <= Duration.zero
        ? 0.0
        : (remaining.inMilliseconds / window.inMilliseconds).clamp(0.0, 1.0);
    final barColor = remaining.secondsUp <= 2
        ? arena.countdownDanger
        : arena.countdownWarn;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.md.h,
        AppSpacing.screenMargin.w,
        0,
      ),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: arena.cardPlate,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: arena.ownCardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: arena.cardLedge,
              offset: Offset(0, AppElevation.ledge.h),
            ),
          ],
        ),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    requester.avatarEmoji,
                    style: AppTypography.glyph(24.sp),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.duelIncomingTitle(requester.displayName(l10n)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall!.copyWith(
                            color: arena.cardInk,
                          ),
                        ),
                        Text(
                          '${requester.leagueEmoji} ${l10n.duelIncomingMeta(requester.leagueName, requester.elo, topicName, requester.topicLevel)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium!.copyWith(
                            color: arena.cardInkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm.h),
              ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pillAll,
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: barHeight.h,
                          color: barColor,
                          backgroundColor: arena.cardChip,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Text(
                      '${AppFormat.plain(remaining.secondsUp, l10n.localeName)}s',
                      style: textTheme.labelMedium!.copyWith(
                        color: arena.cardInk,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    if (request.queuedCount > 0) ...[
                      SizedBox(width: AppSpacing.sm.w),
                      Text(
                        l10n.duelIncomingMore(request.queuedCount),
                        style: textTheme.labelMedium!.copyWith(
                          color: arena.cardInkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Expanded(
                    child: ChunkyButton.ghost(
                      label: l10n.duelIncomingDecline,
                      isSmall: true,
                      onPressed: onDecline,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: ChunkyButton.success(
                      label: l10n.duelIncomingAccept,
                      icon: const Text('⚔️'),
                      isSmall: true,
                      onPressed: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
