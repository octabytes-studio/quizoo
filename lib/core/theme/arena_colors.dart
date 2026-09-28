import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/app_colors.dart';

/// The play surface's palette — §09 of the design bible calls the arena
/// "the one place the app commits to a single look".
///
/// These values are **identical in light and dark**. A widget painting the
/// arena must never branch on `Theme.of(context).brightness`; it reads these
/// tokens and gets the same dark gradient either way. That is why the arena is
/// its own [ThemeExtension] rather than more fields on `QuizooColors` — the
/// type makes the invariance obvious at the call site.
@immutable
class ArenaColors extends ThemeExtension<ArenaColors> {
  const ArenaColors();

  /// `.play` — `linear-gradient(178deg,#2A1B5E 0%,#160E36 62%,#0E0824 100%)`.
  ///
  /// CSS angles run clockwise from "to top"; 178deg is very slightly past
  /// straight down, which is the tilt reproduced by the begin/end alignments.
  LinearGradient get base => const LinearGradient(
    begin: Alignment(-0.0349, -1),
    end: Alignment(0.0349, 1),
    colors: [Color(0xFF2A1B5E), Color(0xFF160E36), Color(0xFF0E0824)],
    stops: [0, 0.62, 1],
  );

  /// The last-5-seconds danger wash (S-14) —
  /// `linear-gradient(178deg,#5A1030 0%,#38091F 60%,#1E0512 100%)`.
  LinearGradient get danger => const LinearGradient(
    begin: Alignment(-0.0349, -1),
    end: Alignment(0.0349, 1),
    colors: [Color(0xFF5A1030), Color(0xFF38091F), Color(0xFF1E0512)],
    stops: [0, 0.60, 1],
  );

  /// The "lite" grape arena used by the duel surface (`.play.lite`) —
  /// `linear-gradient(178deg,#7B4DFF 0%,#5F32E6 55%,#4B22C4 100%)`.
  LinearGradient get lite => const LinearGradient(
    begin: Alignment(-0.0349, -1),
    end: Alignment(0.0349, 1),
    colors: [Color(0xFF7B4DFF), Color(0xFF5F32E6), Color(0xFF4B22C4)],
    stops: [0, 0.55, 1],
  );

  /// All arena foreground text and iconography.
  Color get onArena => Colors.white;

  /// Translucent chrome on the arena — HUD close button (`.play .hud .x`).
  Color get chrome => Colors.white.withValues(alpha: 0.14);

  /// Question card fill (`.qbox`).
  Color get questionCard => Colors.white.withValues(alpha: 0.09);

  /// Question card hairline (`.qbox`).
  Color get questionCardBorder => Colors.white.withValues(alpha: 0.16);

  /// Resting answer option plate (`.opt`).
  Color get optionRest => Colors.white.withValues(alpha: 0.97);

  /// Resting answer option's ledge — `0 4px 0 rgba(0,0,0,.22)`.
  Color get optionRestShadow => Colors.black.withValues(alpha: 0.22);

  /// Eliminated ("gone") answer option plate at 24% opacity.
  Color get optionGone => Colors.white.withValues(alpha: 0.30);

  /// Power-up dock tile fill (`.pup`).
  Color get powerUpTile => Colors.white.withValues(alpha: 0.13);

  /// Power-up dock tile hairline (`.pup`).
  Color get powerUpBorder => Colors.white.withValues(alpha: 0.18);

  /// Unvisited question dot (`.qdots i`).
  Color get questionDot => Colors.white.withValues(alpha: 0.22);

  /// Secondary HUD meta text (`.qmeta`).
  Color get metaText => Colors.white.withValues(alpha: 0.72);

  // ------------------------------------------------ Duel Arena (plan 017)

  /// A challenge card's white plate — same as [optionRest].
  Color get cardPlate => Colors.white.withValues(alpha: 0.97);

  /// Ink on a white card plate (bible `--tx`, light).
  Color get cardInk => AppColors.lightTx;

  /// Secondary ink on a white card plate (bible `--tx2`, light).
  Color get cardInkMuted => AppColors.lightTx2;

  /// A tappable card's 4px hard ledge — same as [optionRestShadow].
  Color get cardLedge => Colors.black.withValues(alpha: 0.22);

  /// The pulsing "● LIVE" dot on an in-progress challenge (raspberry).
  Color get liveDot => AppColors.lightBad;

  /// The border on the viewer's own challenge card (lemon).
  Color get ownCardBorder => AppColors.lightGold;

  /// Countdown ring with plenty of time left (mint).
  Color get countdownSafe => AppColors.lightOk;

  /// Countdown ring under two minutes (lemon).
  Color get countdownWarn => AppColors.lightGold;

  /// Countdown ring under thirty seconds (raspberry).
  Color get countdownDanger => AppColors.lightBad;

  /// The "BOT" pill on the practice bot's avatar (lemon; ink `onGold`).
  Color get botBadge => AppColors.lightGold;

  /// A chip, countdown track or avatar well on a white card plate — the
  /// light sunken fill (`--s3`), kept invariant like the plate itself.
  Color get cardChip => AppColors.lightS3;

  /// The grape outline on a challenge card whose creator is deciding on the
  /// viewer's request.
  Color get pendingGlow => AppColors.lightG;

  @override
  ArenaColors copyWith() => const ArenaColors();

  /// The arena is deliberately invariant, so there is nothing to interpolate
  /// between: a light↔dark theme animation must not move these values.
  @override
  ArenaColors lerp(ThemeExtension<ArenaColors>? other, double t) => this;
}

/// `context.arena.base` instead of
/// `Theme.of(context).extension<ArenaColors>()!.base`.
extension ArenaColorsX on BuildContext {
  ArenaColors get arena => Theme.of(this).extension<ArenaColors>()!;
}
