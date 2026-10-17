import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/profile/data/profile_api.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-52 — delete account.
///
/// A typed-username gate, case-sensitive and exact (plan 004's Edge cases: a
/// trimmed or case-insensitive match would weaken the deliberate friction),
/// with "Delete permanently" disabled until it matches. Deletion is real
/// (plan 025): [SessionCubit.deleteAccount] calls the `delete-account` Edge
/// Function, which erases the auth user and every owned row server-side
/// before the device drops back to Guest.
///
/// Guests have no account to erase, so the screen renders an informational
/// guard instead of the destructive flow — a reviewer reaching this route
/// (or a deep link) before creating an account is never shown a dead-end
/// destructive button.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key, @visibleForTesting this.profileCubit});

  /// Test seam: drives the screen from a given Cubit instead of building one
  /// against the real backend.
  final ProfileCubit? profileCubit;

  @override
  Widget build(BuildContext context) {
    final injected = profileCubit;
    if (injected != null) {
      return BlocProvider<ProfileCubit>.value(
        value: injected,
        child: const _DeleteAccountView(),
      );
    }
    return BlocProvider<ProfileCubit>(
      create: (_) =>
          ProfileCubit(ProfileRepository(ProfileApi(supabase)))..load(),
      child: const _DeleteAccountView(),
    );
  }
}

class _DeleteAccountView extends StatefulWidget {
  const _DeleteAccountView();

  @override
  State<_DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<_DeleteAccountView> {
  final TextEditingController _controller = TextEditingController();
  bool _isDeleting = false;
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _typed = _controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deletePermanently() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    // Captured before the await: the cubit flips to Guest the moment the
    // server confirms, which must not matter to the pop below.
    final session = context.read<SessionCubit>();
    setState(() => _isDeleting = true);
    try {
      await session.deleteAccount();
    } on ApiException {
      // The account is untouched server-side — keep the screen (and the
      // typed username) exactly where they were and say so.
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackbar.show(
        context,
        title: l10n.deleteAccountError,
        intent: SnackbarIntent.error,
      );
      return;
    }
    if (!mounted) return;
    // Shown on the root messenger before the pop, so it survives it.
    AppSnackbar.show(
      context,
      title: l10n.deleteAccountDone,
      intent: SnackbarIntent.info,
    );
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isGuest = context.watch<SessionCubit>().state is SessionGuest;

    return Scaffold(
      backgroundColor: quizoo.ov,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w + 2.w),
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                final summary = state is ProfileLoaded ? state.summary : null;
                final matches =
                    summary != null &&
                    _typed == summary.username &&
                    _typed.isNotEmpty;

                return Container(
                  padding: EdgeInsets.fromLTRB(
                    22.w,
                    AppSpacing.xl.h,
                    22.w,
                    AppSpacing.lg.h,
                  ),
                  decoration: BoxDecoration(
                    color: quizoo.s1,
                    borderRadius: AppRadius.dialogAll,
                    boxShadow: quizoo.shadowLarge,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 66.w,
                          height: 66.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: quizoo.badBg,
                            borderRadius: BorderRadius.circular(
                              AppRadius.dialogIcon.r,
                            ),
                          ),
                          child: Text('🗑️', style: AppTypography.glyph(33.sp)),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      Text(
                        isGuest
                            ? l10n.deleteAccountGuestTitle
                            : l10n.deleteAccountTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineLarge,
                      ),
                      SizedBox(height: 6.h),
                      if (isGuest)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.sm.h),
                          child: Text(
                            l10n.deleteAccountGuestBody,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall,
                          ),
                        )
                      else if (summary == null) ...[
                        SizedBox(height: AppSpacing.sm.h),
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: quizoo.bad,
                          ),
                        ),
                      ] else
                        Text(
                          l10n.deleteAccountBody(
                            summary.totalPoints,
                            summary.badgeCount,
                            summary.dayStreak,
                          ),
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      SizedBox(height: AppSpacing.base.h),
                      if (!isGuest && summary != null) ...[
                        Text(
                          l10n.deleteAccountTypeUsername(summary.username),
                          textAlign: TextAlign.center,
                          style: textTheme.labelSmall,
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                        TextField(
                          controller: _controller,
                          textAlign: TextAlign.center,
                          enabled: !_isDeleting,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: quizoo.s3,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button.r,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            hintText: summary.username,
                          ),
                        ),
                      ],
                      if (_isDeleting && !isGuest) ...[
                        Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: quizoo.bad,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                      ],
                      SizedBox(height: AppSpacing.base.h + 2.h),
                      ChunkyButton.ghost(
                        label: isGuest
                            ? l10n.commonBack
                            : l10n.deleteAccountKeep,
                        onPressed: _isDeleting ? null : context.pop,
                      ),
                      if (!isGuest) ...[
                        SizedBox(height: 9.h),
                        ChunkyButton.danger(
                          label: l10n.deleteAccountDelete,
                          onPressed: matches && !_isDeleting
                              ? _deletePermanently
                              : null,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
