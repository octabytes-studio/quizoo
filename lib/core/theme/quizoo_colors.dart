import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/app_colors.dart';

/// The design bible's semantic colour tokens, carried on [ThemeData] so every
/// widget reads one name (`ln`, `p`, `okBg`, …) and gets the right value for
/// the active brightness.
///
/// Material's own [ColorScheme] has no slot for most of these — a "sunken
/// track" surface, a button's hard ledge shade, a hairline that is neither
/// `outline` nor `outlineVariant`. Rather than approximate, the bible's tokens
/// live here 1:1 with their CSS custom-property names.
///
/// Read it via `Theme.of(context).extension<QuizooColors>()!` or the
/// [QuizooColorsX] shorthand: `context.quizoo.p`.
@immutable
class QuizooColors extends ThemeExtension<QuizooColors> {
  const QuizooColors({
    required this.s0,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.tx,
    required this.tx2,
    required this.tx3,
    required this.ln,
    required this.p,
    required this.pDown,
    required this.pShadow,
    required this.g,
    required this.gShadow,
    required this.ok,
    required this.okShadow,
    required this.okBg,
    required this.bad,
    required this.badShadow,
    required this.badBg,
    required this.info,
    required this.gold,
    required this.goldShadow,
    required this.ov,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.shadow,
    required this.shadowLarge,
  });

  /// App background — `--s0`.
  final Color s0;

  /// Card / sheet surface — `--s1`.
  final Color s1;

  /// Raised / selected surface — `--s2`.
  final Color s2;

  /// Sunken surface, progress track, segmented-control track — `--s3`.
  final Color s3;

  /// Primary text — `--tx`.
  final Color tx;

  /// Secondary text — `--tx2`.
  final Color tx2;

  /// Tertiary / meta text — `--tx3`.
  final Color tx3;

  /// Hairline border — `--ln`.
  final Color ln;

  /// Mango — `--p`.
  final Color p;

  /// Mango, pressed — `--p-d`.
  final Color pDown;

  /// Mango ledge (the hard 4px bottom shadow) — `--p-sh`.
  final Color pShadow;

  /// Grape — `--g`.
  final Color g;

  /// Grape ledge — `--g-sh`.
  final Color gShadow;

  /// Mint — `--ok`.
  final Color ok;

  /// Mint ledge — `--ok-sh`.
  final Color okShadow;

  /// Mint tint background — `--ok-bg`.
  final Color okBg;

  /// Raspberry — `--bad`.
  final Color bad;

  /// Raspberry ledge — `--bad-sh`.
  final Color badShadow;

  /// Raspberry tint background — `--bad-bg`.
  final Color badBg;

  /// Sky — `--info`.
  final Color info;

  /// Lemon — `--gold`.
  final Color gold;

  /// Lemon ledge — `--gold-sh`.
  final Color goldShadow;

  /// Scrim behind sheets and dialogs — `--ov`.
  final Color ov;

  /// Skeleton sweep base — a dedicated pair because `--s3` vanishes on light
  /// `--s0` (plan 021).
  final Color skeleton;

  /// Skeleton sweep highlight — see [skeleton].
  final Color skeletonHighlight;

  /// Card / tile elevation — `--sh`.
  final List<BoxShadow> shadow;

  /// Sheet / dialog / snackbar elevation — `--sh-lg`.
  final List<BoxShadow> shadowLarge;

  /// `--sh: 0 1px 2px rgba(27,20,56,.06), 0 8px 20px -10px rgba(27,20,56,.22)`
  static const List<BoxShadow> _lightShadow = [
    BoxShadow(color: Color(0x0F1B1438), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x381B1438),
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -10,
    ),
  ];

  /// `--sh-lg: 0 -6px 34px -8px rgba(27,20,56,.28)`
  static const List<BoxShadow> _lightShadowLarge = [
    BoxShadow(
      color: Color(0x471B1438),
      offset: Offset(0, -6),
      blurRadius: 34,
      spreadRadius: -8,
    ),
  ];

  /// `--sh: 0 1px 2px rgba(0,0,0,.36), 0 10px 24px -12px rgba(0,0,0,.7)`
  static const List<BoxShadow> _darkShadow = [
    BoxShadow(color: Color(0x5C000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0xB3000000),
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -12,
    ),
  ];

  /// `--sh-lg: 0 -6px 34px -8px rgba(0,0,0,.7)`
  static const List<BoxShadow> _darkShadowLarge = [
    BoxShadow(
      color: Color(0xB3000000),
      offset: Offset(0, -6),
      blurRadius: 34,
      spreadRadius: -8,
    ),
  ];

  static const QuizooColors light = QuizooColors(
    s0: AppColors.lightS0,
    s1: AppColors.lightS1,
    s2: AppColors.lightS2,
    s3: AppColors.lightS3,
    tx: AppColors.lightTx,
    tx2: AppColors.lightTx2,
    tx3: AppColors.lightTx3,
    ln: AppColors.lightLn,
    p: AppColors.lightP,
    pDown: AppColors.lightPd,
    pShadow: AppColors.lightPsh,
    g: AppColors.lightG,
    gShadow: AppColors.lightGsh,
    ok: AppColors.lightOk,
    okShadow: AppColors.lightOkSh,
    okBg: AppColors.lightOkBg,
    bad: AppColors.lightBad,
    badShadow: AppColors.lightBadSh,
    badBg: AppColors.lightBadBg,
    info: AppColors.lightInfo,
    gold: AppColors.lightGold,
    goldShadow: AppColors.lightGoldSh,
    ov: AppColors.lightOv,
    skeleton: AppColors.lightSkeleton,
    skeletonHighlight: AppColors.lightSkeletonHighlight,
    shadow: _lightShadow,
    shadowLarge: _lightShadowLarge,
  );

  static const QuizooColors dark = QuizooColors(
    s0: AppColors.darkS0,
    s1: AppColors.darkS1,
    s2: AppColors.darkS2,
    s3: AppColors.darkS3,
    tx: AppColors.darkTx,
    tx2: AppColors.darkTx2,
    tx3: AppColors.darkTx3,
    ln: AppColors.darkLn,
    p: AppColors.darkP,
    pDown: AppColors.darkPd,
    pShadow: AppColors.darkPsh,
    g: AppColors.darkG,
    gShadow: AppColors.darkGsh,
    ok: AppColors.darkOk,
    okShadow: AppColors.darkOkSh,
    okBg: AppColors.darkOkBg,
    bad: AppColors.darkBad,
    badShadow: AppColors.darkBadSh,
    badBg: AppColors.darkBadBg,
    info: AppColors.darkInfo,
    gold: AppColors.darkGold,
    goldShadow: AppColors.darkGoldSh,
    ov: AppColors.darkOv,
    skeleton: AppColors.darkSkeleton,
    skeletonHighlight: AppColors.darkSkeletonHighlight,
    shadow: _darkShadow,
    shadowLarge: _darkShadowLarge,
  );

  @override
  QuizooColors copyWith({
    Color? s0,
    Color? s1,
    Color? s2,
    Color? s3,
    Color? tx,
    Color? tx2,
    Color? tx3,
    Color? ln,
    Color? p,
    Color? pDown,
    Color? pShadow,
    Color? g,
    Color? gShadow,
    Color? ok,
    Color? okShadow,
    Color? okBg,
    Color? bad,
    Color? badShadow,
    Color? badBg,
    Color? info,
    Color? gold,
    Color? goldShadow,
    Color? ov,
    Color? skeleton,
    Color? skeletonHighlight,
    List<BoxShadow>? shadow,
    List<BoxShadow>? shadowLarge,
  }) {
    return QuizooColors(
      s0: s0 ?? this.s0,
      s1: s1 ?? this.s1,
      s2: s2 ?? this.s2,
      s3: s3 ?? this.s3,
      tx: tx ?? this.tx,
      tx2: tx2 ?? this.tx2,
      tx3: tx3 ?? this.tx3,
      ln: ln ?? this.ln,
      p: p ?? this.p,
      pDown: pDown ?? this.pDown,
      pShadow: pShadow ?? this.pShadow,
      g: g ?? this.g,
      gShadow: gShadow ?? this.gShadow,
      ok: ok ?? this.ok,
      okShadow: okShadow ?? this.okShadow,
      okBg: okBg ?? this.okBg,
      bad: bad ?? this.bad,
      badShadow: badShadow ?? this.badShadow,
      badBg: badBg ?? this.badBg,
      info: info ?? this.info,
      gold: gold ?? this.gold,
      goldShadow: goldShadow ?? this.goldShadow,
      ov: ov ?? this.ov,
      skeleton: skeleton ?? this.skeleton,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      shadow: shadow ?? this.shadow,
      shadowLarge: shadowLarge ?? this.shadowLarge,
    );
  }

  @override
  QuizooColors lerp(ThemeExtension<QuizooColors>? other, double t) {
    if (other is! QuizooColors) return this;
    return QuizooColors(
      s0: Color.lerp(s0, other.s0, t)!,
      s1: Color.lerp(s1, other.s1, t)!,
      s2: Color.lerp(s2, other.s2, t)!,
      s3: Color.lerp(s3, other.s3, t)!,
      tx: Color.lerp(tx, other.tx, t)!,
      tx2: Color.lerp(tx2, other.tx2, t)!,
      tx3: Color.lerp(tx3, other.tx3, t)!,
      ln: Color.lerp(ln, other.ln, t)!,
      p: Color.lerp(p, other.p, t)!,
      pDown: Color.lerp(pDown, other.pDown, t)!,
      pShadow: Color.lerp(pShadow, other.pShadow, t)!,
      g: Color.lerp(g, other.g, t)!,
      gShadow: Color.lerp(gShadow, other.gShadow, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      okShadow: Color.lerp(okShadow, other.okShadow, t)!,
      okBg: Color.lerp(okBg, other.okBg, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      badShadow: Color.lerp(badShadow, other.badShadow, t)!,
      badBg: Color.lerp(badBg, other.badBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldShadow: Color.lerp(goldShadow, other.goldShadow, t)!,
      ov: Color.lerp(ov, other.ov, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      skeletonHighlight: Color.lerp(
        skeletonHighlight,
        other.skeletonHighlight,
        t,
      )!,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t)!,
      shadowLarge: BoxShadow.lerpList(shadowLarge, other.shadowLarge, t)!,
    );
  }
}

/// `context.quizoo.p` instead of
/// `Theme.of(context).extension<QuizooColors>()!.p`.
extension QuizooColorsX on BuildContext {
  QuizooColors get quizoo => Theme.of(this).extension<QuizooColors>()!;
}
