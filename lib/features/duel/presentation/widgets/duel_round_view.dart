import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_badge.dart';
import 'package:quizoo/core/content_language/language_direction.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/content_language_scope.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_audio_button.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_quit_button.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_status_chip.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_verdict_banner.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/timer_ring.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-40's round surface — scores, the round clock, both players' status
/// chips, the question and its options — shared by the live duel and the
/// labelled practice-bot duel (plan 017, Phase 10).
///
/// Purely prop-driven. **Correctness is only ever painted from [correctIndex]
/// once [isRevealed]**: before that the player's own pick shows an hourglass,
/// never a colour (the withheld-correctness rule both Blocs enforce).
///
/// [mySeconds] being non-null is what "my answer is locked" means here (a
/// timeout locks with a null [myChoice]). A null [question] is a round whose
/// question is still on its way — a compact "Get ready…" card.
///
/// Carries play mode's effects too: the 🔊/🔇 toggle, the red, pulsing ring
/// and card border for the last seconds ([isDanger] — the screen washes the
/// arena red alongside), the question sliding in with its options fading in
/// one after another, a green/red ring and a verdict banner at the reveal,
/// and a shake when the player's answer was wrong. Every animation honours
/// reduced motion through [AppMotion].
class DuelRoundView extends StatelessWidget {
  const DuelRoundView({
    required this.me,
    required this.opponent,
    required this.myScore,
    required this.opponentScore,
    required this.roundNumber,
    required this.totalRounds,
    required this.question,
    required this.secondsRemaining,
    required this.secondsTotal,
    required this.languageCode,
    super.key,
    this.myChoice,
    this.mySeconds,
    this.opponentLocked = false,
    this.opponentSeconds,
    this.isRevealed = false,
    this.correctIndex,
    this.opponentChoice,
    this.opponentOnline = true,
    this.opponentReconnectSeconds,
    this.onAnswer,
    this.onQuit,
    this.isAudioOn = false,
    this.onToggleAudio,
    this.isDanger = false,
  });

  final DuelPlayer me;
  final DuelPlayer opponent;
  final int myScore;
  final int opponentScore;
  final int roundNumber;
  final int totalRounds;
  final DuelQuestion? question;
  final int secondsRemaining;
  final int secondsTotal;

  /// The content language the duel's questions are in — the question card
  /// and options follow its direction and script, not the UI locale's.
  final String languageCode;
  final int? myChoice;
  final int? mySeconds;
  final bool opponentLocked;
  final int? opponentSeconds;
  final bool isRevealed;
  final int? correctIndex;
  final int? opponentChoice;
  final bool opponentOnline;
  final int? opponentReconnectSeconds;

  /// Null makes the options inert (and they always are once locked).
  final ValueChanged<int>? onAnswer;

  /// Shows the HUD ✕ when set.
  final VoidCallback? onQuit;

  /// The speaker toggle's state; shown when [onToggleAudio] is set.
  final bool isAudioOn;
  final VoidCallback? onToggleAudio;

  /// The last seconds of an unanswered question.
  final bool isDanger;

  bool get _myLocked => mySeconds != null;

  /// Only meaningful once [isRevealed].
  bool get _myCorrect => myChoice != null && myChoice == correctIndex;

  AnswerOptionState _optionState(int index) {
    if (!isRevealed) {
      return myChoice == index
          ? AnswerOptionState.selected
          : AnswerOptionState.rest;
    }
    if (index == correctIndex) return AnswerOptionState.correct;
    if (myChoice == index) return AnswerOptionState.wrong;
    return AnswerOptionState.eliminated;
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final current = question;
    final answer = onAnswer;
    final canAnswer =
        answer != null && current != null && !_myLocked && !isRevealed;
    final opponentName = opponent.displayName(l10n);
    // Plan 023: `me` is the player's own side, so the local entitlement is
    // OR'd into its badge (see `proBadge`).
    final localIsPro = context.select<SubscriptionCubit, bool>(
      (cubit) => cubit.state.isPro,
    );
    final keys = textDirectionFor(languageCode) == TextDirection.rtl
        ? Question.urduKeys
        : Question.latinKeys;

    return Column(
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin.w,
                AppSpacing.sm.h,
                AppSpacing.screenMargin.w,
                0,
              ),
              child: VsHeader(
                leftAvatarEmoji: me.avatarEmoji,
                leftName: me.displayName(l10n),
                leftIsPro: proBadge(
                  serverIsPro: me.isPro,
                  isSelf: true,
                  localIsPro: localIsPro,
                ),
                leftCaption: '$myScore',
                rightAvatarEmoji: opponent.avatarEmoji,
                rightIsPro: opponent.isPro,
                rightName: opponentName,
                rightCaption: '$opponentScore',
                rightBadge: opponent.isBot ? l10n.duelBotBadge : null,
              ),
            ),
            if (onQuit != null)
              PositionedDirectional(
                start: AppSpacing.screenMargin.w,
                top: AppSpacing.xs.h,
                child: DuelQuitButton(onPressed: onQuit!),
              ),
            if (onToggleAudio != null)
              PositionedDirectional(
                end: AppSpacing.screenMargin.w,
                top: AppSpacing.xs.h,
                child: DuelAudioButton(
                  isOn: isAudioOn,
                  onPressed: onToggleAudio!,
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        TimerRing(
          secondsRemaining: secondsRemaining,
          secondsTotal: secondsTotal,
          color: isRevealed
              ? (_myCorrect ? quizoo.ok : quizoo.bad)
              : (isDanger ? quizoo.bad : quizoo.gold),
          diameter: TimerRing.defaultDiameter,
          isPulsing: isDanger,
        ),
        Text(
          l10n.duelRoundLabel(roundNumber, totalRounds),
          style: textTheme.labelSmall!.copyWith(color: arena.metaText),
        ),
        SizedBox(height: AppSpacing.md.h),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm.w,
          runSpacing: AppSpacing.xs.h,
          children: [
            DuelStatusChip(
              emoji: me.avatarEmoji,
              label: _myLocked
                  ? l10n.duelAnsweredIn(mySeconds!)
                  : l10n.duelThinking,
            ),
            if (opponentOnline)
              DuelStatusChip(
                emoji: opponent.avatarEmoji,
                label: opponentLocked
                    ? l10n.duelAnsweredIn(opponentSeconds ?? 0)
                    : l10n.duelThinking,
              )
            else
              DuelStatusChip(
                emoji: '🔌',
                label: l10n.duelOpponentReconnecting(
                  opponentName,
                  opponentReconnectSeconds ?? 0,
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.md.h),
        // Play mode's `slide`: the next question enters from the side.
        // Keyed on the round, so the clock's rebuilds never replay it.
        Expanded(
          child: PageTransitionSwitcher(
            duration: AppMotion.durationOf(context, AppMotion.slide),
            transitionBuilder: (child, primary, secondary) =>
                SharedAxisTransition(
                  animation: primary,
                  secondaryAnimation: secondary,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Colors.transparent,
                  child: child,
                ),
            child: _ShakeOnWrong(
              key: ValueKey(roundNumber),
              shake: isRevealed && !_myCorrect,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                    child: current == null
                        ? _QuestionCard(
                            text: l10n.duelGetReady,
                            isDanger: isDanger,
                          )
                        : ContentLanguageScope(
                            languageCode: languageCode,
                            child: _QuestionCard(
                              text: current.text,
                              isDanger: isDanger,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: current == null
                              ? const SizedBox.shrink()
                              : ContentLanguageScope(
                                  languageCode: languageCode,
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                      AppSpacing.lg.w,
                                      AppSpacing.md.h,
                                      AppSpacing.lg.w,
                                      AppSpacing.xxl.h * 2,
                                    ),
                                    child: Column(
                                      children: [
                                        for (
                                          var index = 0;
                                          index < current.options.length;
                                          index++
                                        )
                                          _StaggeredEntrance(
                                            index: index,
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                bottom: AppSpacing.sm.h,
                                              ),
                                              child: _OptionTile(
                                                label: current.options[index],
                                                optionKey:
                                                    keys[index % keys.length],
                                                state: _optionState(index),
                                                showHourglass:
                                                    !isRevealed &&
                                                    myChoice == index,
                                                pickedBy: [
                                                  if (isRevealed &&
                                                      myChoice == index)
                                                    me.avatarEmoji,
                                                  if (isRevealed &&
                                                      opponentChoice == index)
                                                    opponent.avatarEmoji,
                                                ],
                                                onPressed: canAnswer
                                                    ? () => answer(index)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        if (isRevealed)
                          PositionedDirectional(
                            start: AppSpacing.lg.w,
                            end: AppSpacing.lg.w,
                            bottom: AppSpacing.base.h,
                            child: DuelVerdictBanner(
                              correct: _myCorrect,
                              timedOut: myChoice == null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.qbox` — the question, or "Get ready…" while it loads.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text, this.isDanger = false});

  final String text;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base.w,
        AppSpacing.base.h,
        AppSpacing.base.w,
        AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: arena.questionCard,
        border: Border.all(
          color: isDanger
              ? context.quizoo.bad.withValues(alpha: 0.5)
              : arena.questionCardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall!.copyWith(color: arena.onArena),
      ),
    );
  }
}

/// One option, plus the marks a duel adds on top: the hourglass on the
/// player's own locked pick (safe — it is their choice, not a verdict), and
/// after the reveal each player's avatar on the option *they* picked — the
/// player's own first — so it is never ambiguous whose pick is whose.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.optionKey,
    required this.state,
    required this.showHourglass,
    required this.onPressed,
    this.pickedBy = const [],
  });

  final String label;
  final String optionKey;
  final AnswerOptionState state;
  final bool showHourglass;

  /// Avatars of whoever picked this option, shown after the reveal.
  final List<String> pickedBy;
  final VoidCallback? onPressed;

  /// One pick marker.
  static const double markerSize = 26;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnswerOption(
          label: label,
          optionKey: optionKey,
          state: state,
          onPressed: onPressed,
        ),
        if (showHourglass)
          PositionedDirectional(
            end: AppSpacing.sm.w,
            top: AppSpacing.sm.h,
            child: Text('⏳', style: AppTypography.glyph(16.sp)),
          ),
        if (pickedBy.isNotEmpty)
          PositionedDirectional(
            end: -AppSpacing.xs.w,
            top: -AppSpacing.sm.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final emoji in pickedBy)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: AppSpacing.xs.w),
                    child: Container(
                      width: markerSize.w,
                      height: markerSize.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: arena.cardPlate,
                        border: Border.all(color: arena.cardLedge),
                      ),
                      child: Text(emoji, style: AppTypography.glyph(14.sp)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Play mode's option entrance — each option fades and rises in a beat after
/// the one above it, once, when the question appears. Implicit (no timers),
/// and instant under reduced motion.
class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  static const Duration _step = Duration(milliseconds: 80);
  static const Duration _entrance = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final total = AppMotion.durationOf(context, _step * index + _entrance);
    if (total == Duration.zero) return child;
    final start = (_step * index).inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOut),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: FractionalTranslation(
          translation: Offset(0, 0.15 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Play mode's S-13 shake (6px / 120ms) when the player's answer was wrong —
/// played once, when [shake] turns true; still under reduced motion.
class _ShakeOnWrong extends StatelessWidget {
  const _ShakeOnWrong({required this.shake, required this.child, super.key});

  final bool shake;
  final Widget child;

  static const Duration _duration = Duration(milliseconds: 120);
  static const double _amplitude = 6;

  @override
  Widget build(BuildContext context) {
    // Always the same wrapper, so the subtree (and its entrance animations)
    // never rebuilds when [shake] flips — only the tween's target moves.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: shake ? 1 : 0),
      duration: AppMotion.durationOf(context, _duration),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(
          _amplitude.w * math.sin(value * math.pi * 4) * (1 - value),
          0,
        ),
        child: child,
      ),
      child: child,
    );
  }
}
