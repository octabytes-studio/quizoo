import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/profile/data/profile_api.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quizoo/features/profile/presentation/widgets/stat_strip.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-32 — Profile.
///
/// A public profile (reached by tapping another player from a leaderboard or
/// friends row) is "the same layout minus settings and wallet" — the same
/// screen with [isOwnProfile] gating the settings gear, rather than a
/// duplicate screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.isOwnProfile = true});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    // Every player — guest or signed in — already carries a real Supabase
    // session (main.dart signs guests in anonymously at launch), so
    // `ProfileApi.fetchSummary()` works and returns real data either way.
    // `SessionCubit`'s guest/signed-in split is purely "should we nudge this
    // player to sign in", handled inside `_ProfileLoadedView` — it must never
    // gate whether the profile's own data loads at all.
    return BlocProvider<ProfileCubit>(
      create: (_) =>
          ProfileCubit(ProfileRepository(ProfileApi(supabase)))..load(),
      child: BlocListener<SessionCubit, SessionState>(
        // This screen is one of `StatefulShellRoute.indexedStack`'s four
        // branches, so it's built (and `ProfileCubit.load()`'d) exactly
        // once and kept alive for the rest of the session — it never
        // rebuilds on a tab switch. Without this listener, a fresh sign-up
        // or sign-in changes the very `profiles` row this screen already
        // fetched as a guest (username, avatar, country all move from
        // empty/default to the player's own picks), but S-32 keeps showing
        // that pre-signup snapshot until the app is restarted.
        listenWhen: (previous, current) =>
            current is SessionSignedIn && previous is! SessionSignedIn,
        listener: (context, state) => context.read<ProfileCubit>().load(),
        child: _ProfileView(isOwnProfile: isOwnProfile),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.isOwnProfile});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileInitial() ||
          ProfileLoading() => _ProfileSkeleton(isOwnProfile: isOwnProfile),
          // `unauthorized` here means the device's anonymous session itself
          // never established (e.g. `signInAnonymously()` timed out at
          // launch, see main.dart) — there truly is no data to show, unlike
          // the ordinary guest case, which has real data under its anonymous
          // `auth.uid()`. Retrying a plain fetch would just fail again, so
          // this is the one error branch that offers sign-in instead of
          // retry.
          ProfileError(:final error)
              when error.kind == ApiErrorKind.unauthorized =>
            const _ProfileSignInRequired(),
          ProfileError(:final error) => _ProfileError(error: error.code),
          ProfileLoaded(:final summary) => _ProfileLoadedView(
            summary: summary,
            isOwnProfile: isOwnProfile,
          ),
        },
      ),
    );
  }
}

/// The rare edge case where the device has no Supabase session at all — not
/// the ordinary guest path (which has real data under an anonymous session,
/// see [ProfileScreen]), but a failed/timed-out anonymous sign-in at launch.
/// There is nothing to load until the player signs in for real.
class _ProfileSignInRequired extends StatelessWidget {
  const _ProfileSignInRequired();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileHeader(isOwnProfile: true),
          Expanded(
            child: EmptyStateView(
              emoji: '🔐',
              title: l10n.profileGuestTitle,
              message: l10n.profileGuestBody,
              action: ChunkyButton.secondary(
                label: l10n.profileGuestAction,
                onPressed: () => context.push(AppRoutes.saveProgress),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadedView extends StatelessWidget {
  const _ProfileLoadedView({required this.summary, required this.isOwnProfile});

  final ProfileSummary summary;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    // The player's own data is real and already loaded (it lives under
    // their anonymous `auth.uid()` even before they ever sign in) — this
    // only decides whether to nudge them toward turning that anonymous
    // session into a real account, never whether the data above shows.
    final isSignedIn = context.watch<SessionCubit>().state is SessionSignedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(
          summary: summary,
          isOwnProfile: isOwnProfile,
          isSignedIn: isSignedIn,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin.w,
              AppSpacing.base.h,
              AppSpacing.screenMargin.w,
              AppSpacing.xl.h,
            ),
            children: [
              if (isOwnProfile && !isSignedIn) ...[
                const _GuestSignInBanner(),
                SizedBox(height: AppSpacing.xl.h),
              ],
              StatStrip(
                stats: [
                  (
                    AppFormat.compact(summary.totalPoints, localeName),
                    l10n.profileStatPoints,
                  ),
                  ('${summary.totalLevels}', l10n.profileStatLevels),
                  ('${summary.accuracyPercent}%', l10n.profileStatAccuracy),
                  ('${summary.badgeCount}', l10n.profileStatBadges),
                ],
              ),
              SizedBox(height: AppSpacing.xl.h),
              SectionHeader(
                title: l10n.profileRecentBadges,
                actionLabel: l10n.profileAllBadges(summary.badgeCount),
                onActionPressed: () => context.push(AppRoutes.achievements),
              ),
              SizedBox(height: AppSpacing.md.h),
              SizedBox(
                height: 96.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: summary.recentBadges.length,
                  separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
                  itemBuilder: (context, index) {
                    final badge = summary.recentBadges[index];
                    return SizedBox(
                      width: 78.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 78.w,
                            height: 78.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppGradients.tileFromHex(
                                badge.gradientFrom,
                                badge.gradientTo,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.card.r + 4,
                              ),
                            ),
                            child: Text(
                              badge.emoji,
                              style: AppTypography.glyph(36.sp),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            badge.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              SectionHeader(title: l10n.profileBestCategories),
              SizedBox(height: AppSpacing.md.h),
              for (final entry in summary.bestCategories)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: ListRowTile(
                    title: entry.name,
                    subtitle: l10n.profileBestCategoryMeta(
                      entry.levelsCleared,
                      entry.levelCount,
                      entry.starsEarned,
                    ),
                    leadingEmoji: entry.emoji,
                    leadingPlateColor: AppGradients.hex(entry.plateColor),
                    trailingValue: '${entry.accuracyPercent}%',
                    trailingLabel: l10n.profileAccuracyLabel,
                    onTap: () {
                      final subcategory = MockCatalog.subcategoryById(
                        entry.subcategoryId,
                      );
                      context.push(
                        AppRoutes.levelMapPath(
                          subcategory.categoryId,
                          subcategory.id,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The loaded view's guest nudge: real data is already showing above it (the
/// player's anonymous session is a real Supabase identity), so this is an
/// invitation to turn that into a permanent account, not a gate. The sign-in
/// button renders explicitly below the copy rather than relying on the whole
/// card being silently tappable, so the CTA reads as a CTA.
class _GuestSignInBanner extends StatelessWidget {
  const _GuestSignInBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: BorderRadius.circular(AppRadius.listRow.r),
        border: Border.all(color: quizoo.g, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ListRowTile.avatarSize.w,
                height: ListRowTile.avatarSize.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quizoo.s3,
                  border: Border.all(color: quizoo.s1, width: 2),
                ),
                child: Text('🐼', style: AppTypography.glyph(19.sp)),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homePlayingAsGuest,
                      style: textTheme.bodyLarge!.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.14,
                        color: quizoo.tx,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 1.h),
                      child: Text(
                        l10n.profileGuestBannerSubtitle,
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: quizoo.tx3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          SizedBox(
            width: double.infinity,
            child: ChunkyButton.secondary(
              label: l10n.profileGuestAction,
              isSmall: true,
              onPressed: () => context.push(AppRoutes.saveProgress),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.bleed` — the full-bleed cosmic grape→sky header. The XP bar sits inside
/// this gradient "so progress reads as part of who you are, not a widget"
/// (bible, S-32).
///
/// The gradient itself, the settings gear and the avatar frame are never
/// data-dependent, so they render on the very first frame regardless of
/// [summary]. When [summary] is null this is either the [isLoading] state
/// (a shimmering placeholder for identity/level) or the guest state (a
/// fixed 🐼 placeholder, with no level/XP to fake).
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isOwnProfile,
    this.summary,
    this.isLoading = false,
    this.isSignedIn = false,
  });

  final ProfileSummary? summary;
  final bool isOwnProfile;
  final bool isLoading;

  /// Whether this is a real signed-in account rather than a guest's
  /// anonymous session — [summary] is non-null (and its `username` empty)
  /// for both, since a guest's real anonymous profile row has no username
  /// either (see [ProfileScreen]'s own doc comment). This is what actually
  /// tells the two apart, rather than `summary.username.isEmpty`.
  final bool isSignedIn;

  static final _skeletonBase = Colors.white.withValues(alpha: 0.22);
  static final _skeletonHighlight = Colors.white.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final summary = this.summary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.tile(
            const Color(0xFF7B4DFF),
            const Color(0xFF2BB3FF),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin.w,
              6.h,
              AppSpacing.screenMargin.w,
              AppSpacing.base.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    if (isOwnProfile)
                      Semantics(
                        button: true,
                        label: l10n.profileSettings,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.settings),
                          behavior: HitTestBehavior.opaque,
                          child: Text('⚙️', style: AppTypography.glyph(17.sp)),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 74.w,
                      height: 74.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: isLoading
                          ? null
                          : Text(
                              summary?.avatarEmoji ?? '🐼',
                              style: AppTypography.glyph(37.sp),
                            ),
                    ),
                    SizedBox(width: AppSpacing.md.w + 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (summary != null &&
                              isSignedIn &&
                              summary.username.isNotEmpty)
                            Text(
                              summary.username,
                              style: textTheme.displayMedium!.copyWith(
                                fontSize: 22.sp,
                                color: Colors.white,
                              ),
                            )
                          else if (isLoading)
                            SkeletonBox(
                              width: 130.w,
                              height: 20.sp,
                              baseColor: _skeletonBase,
                              highlightColor: _skeletonHighlight,
                            )
                          else
                            Text(
                              l10n.profileGuestUsername,
                              style: textTheme.displayMedium!.copyWith(
                                fontSize: 22.sp,
                                color: Colors.white,
                              ),
                            ),
                          SizedBox(height: 4.h),
                          if (summary != null)
                            Text(
                              // `cityLabel` is a flag (plus a city name S-25
                              // never actually collects, so it's always just
                              // the flag in practice) — shown after the
                              // joined date, not before, and omitted
                              // entirely rather than leaving a stray "·"
                              // when there's no country on file yet.
                              summary.cityLabel.isEmpty
                                  ? summary.joinedLabel
                                  : '${summary.joinedLabel} · '
                                        '${summary.cityLabel}',
                              style: textTheme.bodyMedium!.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            )
                          else if (isLoading)
                            SkeletonBox(
                              width: 90.w,
                              height: 12.sp,
                              baseColor: _skeletonBase,
                              highlightColor: _skeletonHighlight,
                            )
                          else
                            Text(
                              l10n.homePlayingAsGuest,
                              style: textTheme.bodyMedium!.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          if (summary != null || isLoading) ...[
                            SizedBox(height: 7.h),
                            if (summary != null)
                              Row(
                                children: [
                                  AppChip.status(
                                    label:
                                        '${summary.leagueEmoji} '
                                        '${summary.leagueName}',
                                  ),
                                  SizedBox(width: AppSpacing.xs.w + 2.w),
                                  AppChip.status(
                                    label: '🔥 ${summary.dayStreak}',
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  SkeletonBox(
                                    width: 76.w,
                                    height: 22.h,
                                    borderRadius: AppRadius.pillAll,
                                    baseColor: _skeletonBase,
                                    highlightColor: _skeletonHighlight,
                                  ),
                                  SizedBox(width: AppSpacing.xs.w + 2.w),
                                  SkeletonBox(
                                    width: 52.w,
                                    height: 22.h,
                                    borderRadius: AppRadius.pillAll,
                                    baseColor: _skeletonBase,
                                    highlightColor: _skeletonHighlight,
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (summary != null) ...[
                  SizedBox(height: AppSpacing.base.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.profileLevelLine(
                            summary.playerLevel,
                            summary.rankTitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall!.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm.w),
                      Text(
                        '${summary.xpIntoLevel} / ${summary.xpToNextLevel} XP',
                        maxLines: 1,
                        style: textTheme.labelSmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.r),
                    child: SizedBox(
                      height: 6.h,
                      child: LinearProgressIndicator(
                        value: summary.xpProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.24),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFC61A),
                        ),
                      ),
                    ),
                  ),
                ] else if (isLoading) ...[
                  SizedBox(height: AppSpacing.base.h),
                  SkeletonBox(
                    width: 150.w,
                    height: 11.sp,
                    baseColor: _skeletonBase,
                    highlightColor: _skeletonHighlight,
                  ),
                  SizedBox(height: 7.h),
                  SkeletonBox(
                    height: 6.h,
                    borderRadius: BorderRadius.circular(3.r),
                    baseColor: _skeletonBase,
                    highlightColor: _skeletonHighlight,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The loading state's full-screen shape: the real gradient header (with
/// shimmering placeholders standing in for identity/level) stays visible
/// immediately, and everything below it is shape-matched to
/// [_ProfileLoadedView] rather than a handful of generic grey bars.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({required this.isOwnProfile});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(isOwnProfile: isOwnProfile, isLoading: true),
        Expanded(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin.w,
              AppSpacing.base.h,
              AppSpacing.screenMargin.w,
              AppSpacing.xl.h,
            ),
            children: [
              SkeletonBox(height: 78.h, borderRadius: AppRadius.cardAll),
              SizedBox(height: AppSpacing.xl.h),
              SectionHeader(title: l10n.profileRecentBadges),
              SizedBox(height: AppSpacing.md.h),
              SizedBox(
                height: 96.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
                  itemBuilder: (_, _) => SkeletonBox(
                    width: 78.w,
                    height: 78.w,
                    borderRadius: BorderRadius.circular(AppRadius.card.r + 4),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              SectionHeader(title: l10n.profileBestCategories),
              SizedBox(height: AppSpacing.md.h),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: SkeletonBox(
                    height: 66.h,
                    borderRadius: BorderRadius.circular(AppRadius.listRow.r),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Center(
        child: ErrorStateView(
          title: l10n.contentErrorTitle,
          emoji: '🛰️',
          message: l10n.contentErrorBody,
          errorCode: error,
          action: ChunkyButton(
            label: l10n.commonRetry,
            onPressed: () => context.read<ProfileCubit>().load(),
          ),
        ),
      ),
    );
  }
}
