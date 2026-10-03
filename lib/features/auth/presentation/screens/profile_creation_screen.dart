import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/data/avatars_api.dart';
import 'package:quizoo/features/auth/data/avatars_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/avatar_picker_cubit.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/auth/presentation/widgets/avatar_picker_sheet.dart';
import 'package:quizoo/features/auth/presentation/widgets/country_picker_sheet.dart';
import 'package:quizoo/features/auth/presentation/widgets/language_picker_sheet.dart';
import 'package:quizoo/features/auth/presentation/widgets/profile_field.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';
import 'package:quizoo/core/content_language/languages_api.dart';
import 'package:quizoo/core/content_language/languages_repository.dart';
import 'package:quizoo/core/content_language/language_flags.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/features/onboarding/presentation/bloc/language_picker_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-25 — profile creation and its field errors.
///
/// Two rules from the bible drive the whole screen, and both are about not
/// punishing the player mid-thought:
///
/// * **Inline validation only after blur.** Nobody is told their email is
///   wrong while they are still typing it.
/// * **Error copy says what to _do_.** "Add the part after the @ — like
///   gmail.com", never "invalid email".
///
/// And the CTA stays **visibly disabled** rather than disappearing, so nobody
/// goes hunting for it.
class ProfileCreationScreen extends StatelessWidget {
  const ProfileCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
      child: const _ProfileCreationView(),
    );
  }
}

class _ProfileCreationView extends StatefulWidget {
  const _ProfileCreationView();

  @override
  State<_ProfileCreationView> createState() => _ProfileCreationViewState();
}

class _ProfileCreationViewState extends State<_ProfileCreationView> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();

  late String _avatarKey;
  late Country _country;

  /// A vendor (Google/Apple) sign-in already carries the player's email from
  /// Supabase, so S-25 skips its email field entirely for that route — only
  /// the email route still needs to collect one (plan 015).
  late bool _isVendorSignIn;

  /// Errors only appear once a field has been left, which is the whole point
  /// of tracking these separately from the values.
  bool _usernameTouched = false;
  bool _emailTouched = false;

  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionCubit>().state.user;
    _avatarKey = user?.avatarEmoji ?? '🐼';
    _country =
        CountryService().findByCode('PK') ?? CountryService().getAll().first;
    _isVendorSignIn = user?.provider != AuthProvider.email;
    _username.text = user?.suggestedDisplayName ?? '';
    _username.addListener(_onUsernameChanged);
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    setState(() {
      _isUsernameAvailable = null;
      _isCheckingUsername = _username.text.trim().length >= 3;
    });
    _usernameDebounce?.cancel();
    if (!_isCheckingUsername) return;
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
    // A newer keystroke has already superseded this lookup.
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

  Future<void> _pickCountry() async {
    final result = await AppBottomSheet.show<Country>(
      context,
      builder: (_) => CountryPickerSheet(selectedCode: _country.countryCode),
    );
    if (result != null) setState(() => _country = result);
  }

  Future<void> _pickLanguage() async {
    // `ContentLanguageCubit` is provided at the app root (above the
    // Navigator), so it's already visible inside the sheet's route — only
    // the screen-local `LanguagePickerCubit` needs forwarding explicitly.
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

  String? _emailError(AppLocalizations l10n) {
    if (!_emailTouched) return null;
    final value = _email.text.trim();
    if (value.isEmpty) return l10n.profileEmailMissing;
    // The bible's own example: `waleed@` is missing everything after the @.
    if (!_isCompleteEmail(value)) return l10n.profileEmailIncomplete;
    return null;
  }

  static bool _isCompleteEmail(String value) {
    final parts = value.split('@');
    return parts.length == 2 &&
        parts.first.isNotEmpty &&
        parts.last.contains('.') &&
        !parts.last.endsWith('.');
  }

  bool get _isValid =>
      _username.text.trim().length >= 3 &&
      _isUsernameAvailable == true &&
      (_isVendorSignIn || _isCompleteEmail(_email.text.trim()));

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<SessionCubit>().state.user;

    try {
      await context.read<SessionCubit>().createProfile(
        username: _username.text.trim(),
        email: _isVendorSignIn ? user!.email! : _email.text.trim(),
        avatarEmoji: _avatarKey,
        countryCode: _country.countryCode,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      // Defence in depth (plan 023, 6.5) — see Edit Profile's twin.
      AppSnackbar.show(
        context,
        title: error.code == 'pro_avatar_required'
            ? l10n.proAvatarRequired
            : l10n.profileUpdateError,
        intent: SnackbarIntent.error,
      );
      return;
    }
    if (!mounted) return;

    AppSnackbar.show(
      context,
      title: l10n.profileCreated,
      intent: SnackbarIntent.success,
      emoji: '🎉',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
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

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin.w,
                AppSpacing.xs.h,
                AppSpacing.screenMargin.w,
                AppSpacing.md.h,
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: l10n.commonBack,
                    child: GestureDetector(
                      onTap: context.pop,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: HomeIconButton.size.w,
                        height: HomeIconButton.size.w,
                        child: Center(
                          child: Text(
                            '←',
                            style: AppTypography.glyph(
                              20.sp,
                              color: quizoo.tx2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: Text(
                      l10n.profileTitle,
                      style: textTheme.titleLarge!.copyWith(fontSize: 19.sp),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin.w,
                ),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      behavior: HitTestBehavior.opaque,
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
                              _avatarKey,
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
                  SizedBox(height: AppSpacing.base.h),
                  ProfileField(
                    label: l10n.profileUsername,
                    controller: _username,
                    error: _usernameError(l10n),
                    onBlur: () => setState(() => _usernameTouched = true),
                    trailing: switch ((
                      _isCheckingUsername,
                      _isUsernameAvailable,
                    )) {
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
                    label: l10n.profileCountry,
                    value: _country.name,
                    leadingEmoji: _country.flagEmoji,
                    onTap: _pickCountry,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  ProfilePickerField(
                    label: l10n.profileLanguage,
                    value: languageName ?? language.code.toUpperCase(),
                    leadingEmoji: languageFlag,
                    onTap: _pickLanguage,
                  ),
                  if (!_isVendorSignIn) ...[
                    SizedBox(height: AppSpacing.md.h),
                    ProfileField(
                      label: l10n.profileEmail,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      error: _emailError(l10n),
                      onBlur: () => setState(() => _emailTouched = true),
                    ),
                  ],
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
                label: l10n.profileCreate,
                // Disabled, never hidden — the shape does not move when it
                // becomes usable.
                onPressed: _isValid ? _create : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

LanguageOption? _findLanguage(List<LanguageOption> languages, String code) {
  for (final option in languages) {
    if (option.code == code) return option;
  }
  return null;
}
