import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
/// with "Delete permanently" disabled until it matches. Mock delete just
/// signs out to Guest and shows a snackbar — there is no real account to
/// erase (plan 004, Scope).
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => ProfileCubit(ProfileRepository(ProfileApi()))..load(),
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

  void _deletePermanently(BuildContext context) {
    context.read<SessionCubit>().continueAsGuest();
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppSnackbar.show(
      context,
      title: AppLocalizations.of(context).deleteAccountDone,
      intent: SnackbarIntent.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

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
                        l10n.deleteAccountTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineLarge,
                      ),
                      SizedBox(height: 6.h),
                      if (summary == null) ...[
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
                      if (summary != null) ...[
                        Text(
                          l10n.deleteAccountTypeUsername(summary.username),
                          textAlign: TextAlign.center,
                          style: textTheme.labelSmall,
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                        TextField(
                          controller: _controller,
                          textAlign: TextAlign.center,
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
                      SizedBox(height: AppSpacing.base.h + 2.h),
                      ChunkyButton.ghost(
                        label: l10n.deleteAccountKeep,
                        onPressed: context.pop,
                      ),
                      SizedBox(height: 9.h),
                      ChunkyButton.danger(
                        label: l10n.deleteAccountDelete,
                        onPressed: matches
                            ? () => _deletePermanently(context)
                            : null,
                      ),
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
