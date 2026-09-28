import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/data/matchmaking_api.dart';
import 'package:quizoo/features/duel/data/matchmaking_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/matchmaking_cubit.dart';
import 'package:quizoo/features/duel/presentation/screens/bot_duel_args.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_topic_picker_sheet.dart';
import 'package:quizoo/features/duel/presentation/widgets/matchmaking_bot_offer.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-39 — quick match in one topic (plan 017, Phase 9).
///
/// Normally pushed from the arena's topic picker with a [topic]. A null
/// [topic] (a design-review deep link) opens the picker first, and the
/// matchmaking session only starts once a topic has been picked.
class MatchmakingScreen extends StatelessWidget {
  const MatchmakingScreen({
    super.key,
    this.topic,
    @visibleForTesting this.cubit,
  });

  /// The topic to match in. Null only for a design-review deep link.
  final DuelTopic? topic;

  /// Test seam: drives the screen from a given Cubit instead of building
  /// one against the real backend.
  final MatchmakingCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final injected = cubit;
    if (injected != null) {
      return BlocProvider<MatchmakingCubit>.value(
        value: injected,
        child: const _MatchmakingView(),
      );
    }
    final resolved = topic;
    if (resolved == null) return const _TopicGate();
    return _MatchmakingSession(key: ValueKey(resolved.id), topic: resolved);
  }
}

/// Owns the [MatchmakingCubit] for one topic.
class _MatchmakingSession extends StatelessWidget {
  const _MatchmakingSession({required this.topic, super.key});

  final DuelTopic topic;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakingCubit>(
      create: (context) {
        final clock = context.read<ServerClock>();
        final cubit = MatchmakingCubit(
          MatchmakingRepository(
            MatchmakingApi(supabase, context.read<DuelRealtime>()),
            clock,
          ),
          DuelRepository(DuelApi(supabase)),
          clock,
          topic: topic,
        );
        unawaited(cubit.start());
        return cubit;
      },
      child: const _MatchmakingView(),
    );
  }
}

/// The deep-link path: asks for a topic first, then starts the session.
///
/// The picked topic is held in `setState` — which topic this route is for
/// is ephemeral navigation state with no business meaning of its own. The
/// matchmaking data itself lives in the Cubit the session creates.
class _TopicGate extends StatefulWidget {
  const _TopicGate();

  @override
  State<_TopicGate> createState() => _TopicGateState();
}

class _TopicGateState extends State<_TopicGate> {
  DuelTopic? _topic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickTopic());
  }

  Future<void> _pickTopic() async {
    final picked = await DuelTopicPickerSheet.show(
      context,
      purpose: DuelTopicPurpose.matchmake,
    );
    if (!mounted) return;
    if (picked == null) {
      _leave(context);
      return;
    }
    setState(() => _topic = picked);
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    if (topic != null) {
      return _MatchmakingSession(key: ValueKey(topic.id), topic: topic);
    }
    return _ArenaScaffold(
      onClose: () => _leave(context),
      child: const _JoiningView(),
    );
  }
}

/// Pops back to where the player came from, or to the arena when this
/// route was opened directly with nothing under it.
void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.duelArena);
  }
}

class _MatchmakingView extends StatelessWidget {
  const _MatchmakingView();

  void _onStateChanged(BuildContext context, MatchmakingState state) {
    switch (state) {
      case MatchmakingFound(:final duelId):
        _pairedHaptic(context);
        context.pushReplacement(AppRoutes.duelPlayPath(duelId));
      case MatchmakingBotReady(:final me, :final opponent, :final topic):
        context.pushReplacement(
          AppRoutes.duelBot,
          extra: BotDuelArgs(me: me, opponent: opponent, topic: topic),
        );
      case MatchmakingJoining() ||
          MatchmakingSearching() ||
          MatchmakingFailed():
        break;
    }
  }

  void _pairedHaptic(BuildContext context) {
    if (context.read<SettingsRepository>().current.hapticsOn) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _close(BuildContext context) {
    unawaited(context.read<MatchmakingCubit>().cancel());
    _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchmakingCubit, MatchmakingState>(
      listenWhen: (previous, current) =>
          current is MatchmakingFound || current is MatchmakingBotReady,
      listener: _onStateChanged,
      builder: (context, state) {
        return _ArenaScaffold(
          onClose: () => _close(context),
          child: switch (state) {
            MatchmakingJoining() => const _JoiningView(),
            final MatchmakingSearching searching => _SearchingView(
              state: searching,
            ),
            // The listener is already replacing the route.
            MatchmakingFound() || MatchmakingBotReady() => const _JoiningView(),
            MatchmakingFailed(:final error) => _FailedView(error: error),
          },
        );
      },
    );
  }
}

/// `arena.base` with the ✕ top-left — shared by every branch, so the way
/// out never moves.
class _ArenaScaffold extends StatelessWidget {
  const _ArenaScaffold({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: arena.base),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin.w,
                    AppSpacing.sm.h,
                    AppSpacing.screenMargin.w,
                    0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _CloseButton(
                      semanticLabel: l10n.duelLeaveQueueLabel,
                      onTap: onClose,
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.semanticLabel, required this.onTap});

  final String semanticLabel;
  final VoidCallback onTap;

  static const double _size = 34;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _size.w,
          height: _size.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: arena.chrome,
            borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
          ),
          child: ExcludeSemantics(
            child: Text(
              '✕',
              style: AppTypography.glyph(15.sp, color: arena.onArena),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32.w,
      child: CircularProgressIndicator(
        color: context.arena.onArena,
        strokeWidth: 3,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).duelMatchmakingTitle,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayMedium!.copyWith(
        fontSize: 24.sp,
        color: context.arena.onArena,
      ),
    );
  }
}

class _JoiningView extends StatelessWidget {
  const _JoiningView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Title(),
          SizedBox(height: AppSpacing.xl.h),
          const _Spinner(),
        ],
      ),
    );
  }
}

class _SearchingView extends StatelessWidget {
  const _SearchingView({required this.state});

  final MatchmakingSearching state;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final cubit = context.read<MatchmakingCubit>();
    final me = state.me;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
      child: Column(
        children: [
          const Spacer(),
          const _Title(),
          SizedBox(height: AppSpacing.sm.h),
          _TopicChip(topic: state.topic),
          SizedBox(height: AppSpacing.xl.h),
          _FitToWidth(
            child: VsHeader(
              leftAvatarEmoji: me.avatarEmoji,
              leftCaption: l10n.duelLeagueEloCaption(
                '${me.leagueEmoji} ${me.leagueName}',
                AppFormat.number(me.elo, localeName),
              ),
              rightCaption: l10n.duelSearchingBand(
                state.bandMin,
                state.bandMax,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
          const _Spinner(),
          SizedBox(height: AppSpacing.base.h),
          Text(
            l10n.duelSearchingStatus(
              state.elapsedSeconds,
              state.secondsToNextWiden,
            ),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(color: arena.metaText),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: AppMotion.durationOf(context, AppMotion.slide),
            switchInCurve: AppMotion.curveOf(context, AppMotion.slideCurve),
            switchOutCurve: AppMotion.curveOf(context, AppMotion.slideCurve),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: state.showBotOffer
                ? MatchmakingBotOffer(
                    key: const ValueKey('bot-offer'),
                    topic: state.topic,
                    onPlayBot: state.isStartingBot
                        ? null
                        : () => unawaited(cubit.playBot()),
                    onKeepSearching: cubit.keepSearching,
                  )
                : const SizedBox.shrink(key: ValueKey('no-bot-offer')),
          ),
          SizedBox(height: AppSpacing.lg.h),
        ],
      ),
    );
  }
}

/// Lays [child] out at the full available width, and scales it down
/// only if its natural width is wider than that.
///
/// The VS row's searching side doesn't ellipsize its caption, and "Searching…
/// 1,140 – 1,340 ELO" next to a long league caption can outgrow a phone's
/// width (Urdu, big ELO numbers). When it fits, the row renders exactly as
/// before, with its `spaceEvenly` spread intact.
class _FitToWidth extends StatelessWidget {
  const _FitToWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// The topic being matched in, under the title.
class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic});

  final DuelTopic topic;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: arena.chrome,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '${topic.emoji} ${topic.name}',
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(color: arena.onArena),
      ),
    );
  }
}

/// Join failed: arena-coloured, with Retry and Back.
class _FailedView extends StatelessWidget {
  const _FailedView({required this.error});

  final ApiException error;

  String _message(AppLocalizations l10n) => switch (error.code) {
    'topic_unavailable' => l10n.duelNoticeTopicUnavailable,
    'rate_limited' => l10n.duelNoticeRateLimited,
    _ when error.isOffline => l10n.contentErrorBody,
    _ => l10n.duelNoticeGeneric,
  };

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final code = error.code;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '⚔️',
              textAlign: TextAlign.center,
              style: AppTypography.glyph(56.sp),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              l10n.contentErrorTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall!.copyWith(
                color: arena.onArena,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              _message(l10n),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium!.copyWith(color: arena.metaText),
            ),
            if (code != null) ...[
              SizedBox(height: AppSpacing.md.h),
              Text(
                code,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                  fontFamily: AppTypography.mono,
                  color: arena.metaText,
                ),
              ),
            ],
            SizedBox(height: AppSpacing.xl.h),
            ChunkyButton(
              label: l10n.commonRetry,
              onPressed: () =>
                  unawaited(context.read<MatchmakingCubit>().start()),
            ),
            SizedBox(height: AppSpacing.sm.h),
            ChunkyButton.ghost(
              label: l10n.commonBack,
              onPressed: () => _leave(context),
            ),
          ],
        ),
      ),
    );
  }
}
