import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/data/avatars_api.dart';
import 'package:quizoo/features/auth/data/avatars_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/avatar_picker_cubit.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/auth/presentation/widgets/avatar_picker_sheet.dart';
import 'package:quizoo/features/auth/presentation/widgets/language_picker_sheet.dart';
import 'package:quizoo/features/auth/presentation/widgets/profile_field.dart';
import 'package:quizoo/core/content_language/languages_api.dart';
import 'package:quizoo/core/content_language/languages_repository.dart';
import 'package:quizoo/core/content_language/language_flags.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/features/onboarding/presentation/bloc/language_picker_cubit.dart';
import 'package:quizoo/features/profile/data/profile_api.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quizoo/features/profile/presentation/widgets/badges_rail.dart';
import 'package:quizoo/features/profile/presentation/widgets/guest_sign_in_banner.dart';
import 'package:quizoo/features/profile/presentation/widgets/stat_strip.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Edit Profile — avatar, display name and language, with view-only stats
/// and badges (plan 019). Reached by tapping the player's own avatar on Home
/// or the You screen.
///
/// A guest can open this screen (their real, if empty, anonymous `profiles`
/// row loads exactly like a signed-in player's — see `ProfileScreen`'s own
/// doc comment) but cannot save an avatar/display-name change: the avatar
/// tap, the username field and the Save button are all disabled, and a
/// [GuestSignInBanner] explains why. The language field stays enabled either
/// way, since content-language selection is never gated behind an account
/// anywhere else in the app.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>(
          create: (_) =>
              ProfileCubit(ProfileRepository(ProfileApi(supabase)))..load(),
        ),
        BlocProvider<AvatarPickerCubit>(
          create: (_) =>
              AvatarPickerCubit(AvatarsRepository(AvatarsApi(supabase)))
                ..load(),
        ),
        BlocProvider<LanguagePickerCubit>(
          create: (_) =>
              LanguagePickerCubit(LanguagesRepository(LanguagesApi(supabase)))
                ..load(),
        ),
      ],
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final TextEditingController _username = TextEditingController();

  late String _avatarKey;
  late String _originalUsername;
  bool _initialized = false;

  bool _usernameTouched = false;
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;
  bool _isSaving = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _username.dispose();
    super.dispose();
  }

  void _seedFrom(String username, String avatarEmoji) {
    _initialized = true;
    _originalUsername = username;
    _username.text = username;
    _avatarKey = avatarEmoji;
    _username.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    setState(() {
      _isUsernameAvailable = null;
      _isCheckingUsername = false;
    });
    _usernameDebounce?.cancel();
    final candidate = _username.text.trim();
    // Assumption 7: unchanged from the original never re-checks, or opening
    // the screen and immediately saving would report the player's own
    // username as taken.
    if (candidate == _originalUsername || candidate.length < 3) return;
    setState(() => _isCheckingUsername = true);
    _usernameDebounce = Timer(
      const Duration(milliseconds: 350),
      _checkUsername,
    );
  }

  Future<void> _checkUsername() async {
    final candidate = _username.text.trim();
    final available = await context.read<AuthRepository>().isUsernameAvailable(
      candidate,
    );
    if (!mounted || candidate != _username.text.trim()) return;
    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = available;
    });
  }

  Future<void> _pickAvatar() async {
    final result = await AppBottomSheet.show<String>(
      context,
      builder: (_) => BlocProvider.value(
        value: context.read<AvatarPickerCubit>(),
        child: AvatarPickerSheet(selectedEmoji: _avatarKey),
      ),
    );
    if (result != null) setState(() => _avatarKey = result);
  }

  Future<void> _pickLanguage() async {
    await AppBottomSheet.show<void>(
      context,
      builder: (_) => BlocProvider.value(
        value: context.read<LanguagePickerCubit>(),
        child: const LanguagePickerSheet(),
      ),
    );
  }

  String? _usernameError(AppLocalizations l10n) {
    if (!_usernameTouched) return null;
    if (_username.text.trim().length < 3) return l10n.profileUsernameTooShort;
    if (_isUsernameAvailable == false) return l10n.profileUsernameTaken;
    return null;
  }

  bool get _isUsernameUnchanged => _username.text.trim() == _originalUsername;

  bool get _canSave =>
      !_isSaving &&
      _username.text.trim().length >= 3 &&
      (_isUsernameUnchanged || _isUsernameAvailable == true);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      await context.read<SessionCubit>().updateProfile(
        username: _username.text.trim(),
        avatarEmoji: _avatarKey,
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        title: l10n.profileChangesSaved,
        intent: SnackbarIntent.success,
        emoji: '🎉',
      );
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      // Defence in depth (plan 023, 6.5): the picker already locks Pro
      // avatars for a free player, but the server is the real gate and this
      // is what its refusal looks like. Plan 025 adds the username-policy
      // refusal, which needs its own copy rather than the generic error.
      AppSnackbar.show(
        context,
        title: switch (error.code) {
          'pro_avatar_required' => l10n.proAvatarRequired,
          'username_not_allowed' => l10n.profileUsernameNotAllowed,
          _ => l10n.profileUpdateError,
        },
        intent: SnackbarIntent.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimpleTopBar(title: l10n.profileEditTitle),
            Expanded(
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) => switch (state) {
                  ProfileInitial() || ProfileLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  ProfileError(:final error) => Center(
                    child: ErrorStateView(
                      title: l10n.contentErrorTitle,
                      emoji: '🛰️',
                      message: l10n.contentErrorBody,
                      errorCode: error.code,
                      action: ChunkyButton(
                        label: l10n.commonRetry,
                        onPressed: () => context.read<ProfileCubit>().load(),
                      ),
                    ),
                  ),
                  ProfileLoaded(:final summary) => Builder(
                    builder: (context) {
                      if (!_initialized) {
                        _seedFrom(summary.username, summary.avatarEmoji);
                      }
                      final isSignedIn =
                          context.watch<SessionCubit>().state
                              is SessionSignedIn;
                      final localeName = Localizations.localeOf(
                        context,
                      ).toLanguageTag();
                      return _EditProfileForm(
                        isSignedIn: isSignedIn,
                        avatarKey: _avatarKey,
                        username: _username,
                        usernameError: _usernameError(l10n),
                        isCheckingUsername: _isCheckingUsername,
                        isUsernameAvailable: _isUsernameAvailable,
                        stats: [
                          (
                            AppFormat.compact(summary.totalPoints, localeName),
                            l10n.profileStatPoints,
                          ),
                          ('${summary.totalLevels}', l10n.profileStatLevels),
                          (
                            '${summary.accuracyPercent}%',
                            l10n.profileStatAccuracy,
                          ),
                          ('${summary.badgeCount}', l10n.profileStatBadges),
                        ],
                        recentBadges: summary.recentBadges,
                        badgeCount: summary.badgeCount,
                        canSave: _canSave,
                        onAvatarTap: _pickAvatar,
                        onLanguageTap: _pickLanguage,
                        onUsernameBlur: () =>
                            setState(() => _usernameTouched = true),
                        onSave: _save,
                      );
                    },
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.isSignedIn,
    required this.avatarKey,
    required this.username,
    required this.usernameError,
    required this.isCheckingUsername,
    required this.isUsernameAvailable,
    required this.stats,
    required this.recentBadges,
    required this.badgeCount,
    required this.canSave,
    required this.onAvatarTap,
    required this.onLanguageTap,
    required this.onUsernameBlur,
    required this.onSave,
  });

  final bool isSignedIn;
  final String avatarKey;
  final TextEditingController username;
  final String? usernameError;
  final bool isCheckingUsername;
  final bool? isUsernameAvailable;
  final List<(String, String)> stats;
  final List<AppBadge> recentBadges;
  final int badgeCount;
  final bool canSave;
  final VoidCallback onAvatarTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onUsernameBlur;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final language = context.watch<ContentLanguageCubit>().state;
    final languageFlag = languageFlags[language.code] ?? '🌐';
    final languageName = switch (context.watch<LanguagePickerCubit>().state) {
      LanguagePickerLoaded(:final languages) => _findLanguage(
        languages,
        language.code,
      )?.nativeName,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            children: [
              if (!isSignedIn) ...[
                const GuestSignInBanner(),
                SizedBox(height: AppSpacing.base.h),
              ],
              Center(
                child: GestureDetector(
                  onTap: isSignedIn ? onAvatarTap : null,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: isSignedIn ? 1 : 0.5,
                    child: Column(
                      children: [
                        Container(
                          width: 88.w,
                          height: 88.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: quizoo.s3,
                            border: Border.all(color: quizoo.g, width: 3),
                          ),
                          child: Text(
                            avatarKey,
                            style: AppTypography.glyph(44.sp),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                        Text(
                          l10n.profileChangeAvatar,
                          style: textTheme.bodyMedium!.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: quizoo.g,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.base.h),
              StatStrip(stats: stats),
              SizedBox(height: AppSpacing.xl.h),
              BadgesRail(
                badges: recentBadges,
                badgeCount: badgeCount,
                onSeeAll: () => context.push(AppRoutes.achievements),
              ),
              SizedBox(height: AppSpacing.xl.h),
              ProfileField(
                label: l10n.profileUsername,
                controller: username,
                enabled: isSignedIn,
                error: usernameError,
                onBlur: onUsernameBlur,
                trailing: !isSignedIn
                    ? null
                    : switch ((isCheckingUsername, isUsernameAvailable)) {
                        (true, _) => SizedBox.square(
                          dimension: 14.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: quizoo.tx3,
                          ),
                        ),
                        (false, true) => Text(
                          l10n.profileUsernameAvailable,
                          style: textTheme.bodyMedium!.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: quizoo.ok,
                          ),
                        ),
                        _ => null,
                      },
              ),
              SizedBox(height: AppSpacing.md.h),
              ProfilePickerField(
                label: l10n.profileLanguage,
                value: languageName ?? language.code.toUpperCase(),
                leadingEmoji: languageFlag,
                onTap: onLanguageTap,
              ),
              SizedBox(height: AppSpacing.xl.h),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.md.h,
            AppSpacing.screenMargin.w,
            AppSpacing.sm.h + 2.h,
          ),
          child: ChunkyButton(
            label: l10n.profileSaveChanges,
            onPressed: isSignedIn && canSave ? onSave : null,
          ),
        ),
      ],
    );
  }

  static LanguageOption? _findLanguage(
    List<LanguageOption> languages,
    String code,
  ) {
    for (final option in languages) {
      if (option.code == code) return option;
    }
    return null;
  }
}
