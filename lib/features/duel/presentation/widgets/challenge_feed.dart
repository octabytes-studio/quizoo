import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/presentation/bloc/challenge_card_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/composer_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_arena_bloc.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The arena's chat-style challenge stream (plan 017, Decision 6): newest at
/// the bottom, bottom-anchored, with a "↓ N new challenges" pill while the
/// viewer is scrolled up.
///
/// Stateful only for the scroll anchor, the pill's count and which cards are
/// still owed their entry animation — ephemeral UI state (CLAUDE.md §3).
/// Every card's state comes from [DuelArenaReady].
class ChallengeFeed extends StatefulWidget {
  const ChallengeFeed({
    required DuelArenaReady this.ready,
    required ValueChanged<String> this.onJoin,
    required ValueChanged<String> this.onWithdraw,
    required VoidCallback this.onCancel,
    required VoidCallback this.onCreate,
    super.key,
  });

  /// Three animated skeleton cards while the snapshot loads.
  const ChallengeFeed.loading({super.key})
    : ready = null,
      onJoin = null,
      onWithdraw = null,
      onCancel = null,
      onCreate = null;

  final DuelArenaReady? ready;
  final ValueChanged<String>? onJoin;
  final ValueChanged<String>? onWithdraw;
  final VoidCallback? onCancel;

  /// The empty feed's "Create challenge" CTA.
  final VoidCallback? onCreate;

  /// How many skeleton cards the loading variant shows.
  static const int skeletonCount = 3;

  @override
  State<ChallengeFeed> createState() => _ChallengeFeedState();
}

class _ChallengeFeedState extends State<ChallengeFeed> {
  final ScrollController _controller = ScrollController();

  /// Every id already on screen at least once.
  final Set<String> _seen = {};

  /// Ids that arrived after the first snapshot and haven't animated in yet.
  final Set<String> _toAnimate = {};

  /// New arrivals while scrolled up.
  int _newCount = 0;

  /// Within this of the bottom counts as "at the bottom".
  static const double _bottomSlack = 24;

  bool get _isAtBottom =>
      !_controller.hasClients || _controller.offset <= _bottomSlack;

  @override
  void initState() {
    super.initState();
    _seen.addAll(_ids(widget.ready?.feedItems));
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ChallengeFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldReady = oldWidget.ready;
    final ready = widget.ready;
    if (ready == null) return;
    if (oldReady == null) {
      // The first snapshot: nothing in it is "new".
      _seen.addAll(_ids(ready.feedItems));
      return;
    }

    final previousNewest = oldReady.feedItems.lastOrNull?.createdAt;
    var appended = 0;
    for (final challenge in ready.feedItems) {
      if (!_seen.add(challenge.id)) continue;
      _toAnimate.add(challenge.id);
      if (previousNewest == null ||
          challenge.createdAt.isAfter(previousNewest)) {
        appended++;
      }
    }
    if (appended == 0 || _isAtBottom) return;

    // Scrolled up: count the arrivals for the pill, and keep the cards the
    // viewer is reading in place while the new ones land below them.
    _newCount += appended;
    final extentBefore = _controller.position.maxScrollExtent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final delta = _controller.position.maxScrollExtent - extentBefore;
      if (delta > 0) _controller.jumpTo(_controller.offset + delta);
    });
  }

  void _onScroll() {
    if (_newCount > 0 && _isAtBottom) setState(() => _newCount = 0);
  }

  void _jumpToNewest() {
    setState(() => _newCount = 0);
    if (!_controller.hasClients) return;
    final duration = AppMotion.durationOf(context, AppMotion.slide);
    if (duration == Duration.zero) {
      _controller.jumpTo(0);
    } else {
      _controller.animateTo(0, duration: duration, curve: AppMotion.slideCurve);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  static Iterable<String> _ids(List<DuelChallenge>? challenges) =>
      (challenges ?? const <DuelChallenge>[]).map((c) => c.id);

  @override
  Widget build(BuildContext context) {
    final ready = widget.ready;
    if (ready == null) return const _FeedSkeleton();

    final challenges = ready.feedItems;
    if (challenges.isEmpty) {
      return _FeedEmpty(
        onCreate: ready.composerState is ComposerCreate
            ? widget.onCreate
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeedHeader(count: ready.challenges.length),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                reverse: true,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin.w,
                  AppSpacing.sm.h,
                  AppSpacing.screenMargin.w,
                  AppSpacing.sm.h,
                ),
                itemCount: challenges.length,
                findChildIndexCallback: (key) {
                  if (key is! ValueKey<String>) return null;
                  final index = challenges.indexWhere((c) => c.id == key.value);
                  return index < 0 ? null : challenges.length - 1 - index;
                },
                itemBuilder: (context, index) {
                  final challenge = challenges[challenges.length - 1 - index];
                  return KeyedSubtree(
                    key: ValueKey<String>(challenge.id),
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.md.h),
                      child: _entry(
                        context,
                        challenge,
                        _card(ready, challenge),
                      ),
                    ),
                  );
                },
              ),
              if (_newCount > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.sm.h,
                  child: Center(
                    child: _NewPill(count: _newCount, onTap: _jumpToNewest),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(DuelArenaReady ready, DuelChallenge challenge) {
    final cardState = ready.cardStateFor(challenge);
    return ChallengeCard(
      challenge: challenge,
      cardState: cardState,
      fairness: ready.fairnessFor(challenge),
      now: ready.now,
      config: ready.config,
      onJoin: cardState is ChallengeCardOpen
          ? () => widget.onJoin?.call(challenge.id)
          : null,
      onWithdraw: () => widget.onWithdraw?.call(challenge.id),
      onCancel: ready.isBusy ? null : widget.onCancel,
    );
  }

  /// New arrivals slide up and fade in, once; nothing moves under reduced
  /// motion.
  Widget _entry(BuildContext context, DuelChallenge challenge, Widget card) {
    if (!_toAnimate.contains(challenge.id)) return card;
    if (AppMotion.reduceMotion(context)) {
      _toAnimate.remove(challenge.id);
      return card;
    }
    final duration = AppMotion.durationOf(context, AppMotion.slide);
    final curve = AppMotion.curveOf(context, AppMotion.slideCurve);
    return card
        .animate(onComplete: (_) => _toAnimate.remove(challenge.id))
        .fadeIn(duration: duration, curve: curve)
        .slideY(begin: 0.3, end: 0, duration: duration, curve: curve);
  }
}

/// "LIVE CHALLENGES · 8".
class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.base.h,
        AppSpacing.screenMargin.w,
        0,
      ),
      child: Semantics(
        header: true,
        child: Text(
          '${l10n.duelLiveChallengesHeader.toUpperCase()} · $count',
          style: textTheme.labelMedium!.copyWith(
            color: arena.metaText,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// "↓ 2 new challenges".
class _NewPill extends StatelessWidget {
  const _NewPill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final label = l10n.duelFeedNewPill(count);

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: AppSpacing.sm.h,
          ),
          decoration: BoxDecoration(
            color: arena.cardPlate,
            borderRadius: AppRadius.pillAll,
            boxShadow: [
              BoxShadow(color: arena.cardLedge, offset: Offset(0, 3.h)),
            ],
          ),
          child: ExcludeSemantics(
            child: Text(
              '↓ $label',
              style: textTheme.labelMedium!.copyWith(color: arena.cardInk),
            ),
          ),
        ),
      ),
    );
  }
}

/// "No live challenges yet — throw down the first one", on the arena's own
/// ink (the app-wide `EmptyStateView` paints theme ink, which the invariant
/// grape arena can't take).
class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty({required this.onCreate});

  /// Null hides the CTA (a guest, a cool-off, or an open challenge).
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final create = onCreate;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🏟️',
              textAlign: TextAlign.center,
              style: AppTypography.glyph(56.sp),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              l10n.duelFeedEmptyTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: arena.onArena,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              l10n.duelFeedEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall!.copyWith(color: arena.metaText),
            ),
            if (create != null) ...[
              SizedBox(height: AppSpacing.xl.h),
              ChunkyButton(
                label: l10n.duelFeedEmptyCta,
                icon: const Text('⚔️'),
                onPressed: create,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Three shimmering card placeholders, bottom-anchored like the real feed.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  static const double cardHeight = 128;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return ListView.separated(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.base.h,
        AppSpacing.screenMargin.w,
        AppSpacing.sm.h,
      ),
      itemCount: ChallengeFeed.skeletonCount,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
      itemBuilder: (_, _) => SkeletonBox(
        height: cardHeight.h,
        borderRadius: AppRadius.cardAll,
        baseColor: arena.questionCard,
        highlightColor: arena.questionCardBorder,
      ),
    );
  }
}
