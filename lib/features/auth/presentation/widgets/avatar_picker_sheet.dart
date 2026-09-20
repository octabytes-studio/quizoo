import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/auth/domain/avatar_option.dart';
import 'package:quizoo/features/auth/presentation/bloc/avatar_picker_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-25's avatar picker — a grid of every active `avatar_options` row
/// (plan 015), replacing the old tap-to-cycle bubble. Tapping an avatar pops
/// the sheet with that emoji; backing out without choosing resolves to null,
/// which the caller (S-25) treats as a no-op.
class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({required this.selectedEmoji, super.key});

  final String selectedEmoji;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBottomSheet(
      title: l10n.profileChooseAvatar,
      child: BlocBuilder<AvatarPickerCubit, AvatarPickerState>(
        builder: (context, state) => switch (state) {
          AvatarPickerLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AvatarPickerError() => ErrorStateView(
            title: l10n.contentErrorTitle,
            message: l10n.contentErrorBody,
            action: ChunkyButton.ghost(
              label: l10n.commonRetry,
              onPressed: () => context.read<AvatarPickerCubit>().load(),
            ),
          ),
          AvatarPickerLoaded(:final avatars) => _AvatarGrid(
            avatars: avatars,
            selectedEmoji: selectedEmoji,
          ),
        },
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({required this.avatars, required this.selectedEmoji});

  final List<AvatarOption> avatars;
  final String selectedEmoji;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.md.h,
        crossAxisSpacing: AppSpacing.md.w,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        return _AvatarBubble(
          emoji: avatar.emoji,
          isSelected: avatar.emoji == selectedEmoji,
        );
      },
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.emoji, required this.isSelected});

  final String emoji;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return GestureDetector(
      onTap: () => Navigator.pop(context, emoji),
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: quizoo.s3,
          border: Border.all(
            color: isSelected ? quizoo.g : quizoo.ln,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(emoji, style: AppTypography.glyph(32.sp)),
            if (isSelected)
              Positioned(
                right: 2.w,
                bottom: 2.h,
                child: Text(
                  '✓',
                  style: AppTypography.glyph(14.sp, color: quizoo.g),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
