import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/pro_upsell_sheet.dart';
import 'package:quizoo/features/auth/domain/avatar_option.dart';
import 'package:quizoo/features/auth/presentation/bloc/avatar_picker_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-25's avatar picker — a grid of every active `avatar_options` row
/// (plan 015), replacing the old tap-to-cycle bubble. Tapping an avatar pops
/// the sheet with that emoji; backing out without choosing resolves to null,
/// which the caller (S-25) treats as a no-op.
///
/// Plan 023 adds the Pro-only set: free avatars first, then a "Quizoo Pro"
/// sub-header and the locked ones wearing a small crown. A free player
/// tapping one gets the Pro upsell sheet and **this sheet stays open**, so
/// they can still pick a free avatar without going round the houses. The
/// server is the real gate — `pro_avatar_required` refuses the write.
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
    final l10n = AppLocalizations.of(context);
    final free = [
      for (final a in avatars)
        if (!a.isPro) a,
    ];
    final pro = [
      for (final a in avatars)
        if (a.isPro) a,
    ];
    final isProMember = context.select<SubscriptionCubit, bool>(
      (cubit) => cubit.state.isPro,
    );
    final canOfferPro = context.select<SubscriptionCubit, bool>((cubit) {
      final state = cubit.state;
      return state is SubscriptionFree && state.isAvailable;
    });

    // Free avatars first, then the Pro set behind a sub-header.
    final rows = <Widget>[
      _AvatarRow(
        avatars: free,
        selectedEmoji: selectedEmoji,
        isProMember: isProMember,
      ),
      if (pro.isNotEmpty) ...[
        SizedBox(height: AppSpacing.lg.h),
        Row(
          children: [
            Text('👑', style: AppTypography.glyph(14.sp)),
            SizedBox(width: AppSpacing.sm.w),
            Text(
              l10n.proAvatarSection,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: context.quizoo.gold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        _AvatarRow(
          avatars: pro,
          selectedEmoji: selectedEmoji,
          isProMember: isProMember,
          // Locked for a free player who cannot even buy Pro here.
          isLocked: !isProMember,
          onLockedTap: canOfferPro
              ? () => ProUpsellSheet.show(
                  context,
                  emoji: '🦄',
                  title: l10n.proUpsellAvatarTitle,
                  message: l10n.proUpsellAvatarBody,
                  source: PaywallSource.proAvatar,
                )
              : null,
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

/// One row of bubbles — the grid is a wrapping row per group so the Pro
/// sub-header can sit between the two sets.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    required this.avatars,
    required this.selectedEmoji,
    required this.isProMember,
    this.isLocked = false,
    this.onLockedTap,
  });

  final List<AvatarOption> avatars;
  final String selectedEmoji;
  final bool isProMember;

  /// True for the Pro set when the player is not a member — the bubble draws
  /// its crown and taps go to [onLockedTap] instead of selecting.
  final bool isLocked;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md.w,
      runSpacing: AppSpacing.md.h,
      children: [
        for (final avatar in avatars)
          SizedBox(
            width: 64.w,
            height: 64.w,
            child: _AvatarBubble(
              emoji: avatar.emoji,
              isSelected: avatar.emoji == selectedEmoji,
              isPro: avatar.isPro,
              isLocked: isLocked,
              onTap: isLocked
                  ? onLockedTap
                  : () => Navigator.pop(context, avatar.emoji),
            ),
          ),
      ],
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.emoji,
    required this.isSelected,
    required this.isPro,
    required this.isLocked,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;

  /// Whether this avatar is in the Pro-only set (draws the crown).
  final bool isPro;

  /// Whether the current player may not select it (draws the lock, and taps
  /// go to [onTap] rather than selecting).
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return GestureDetector(
      onTap: onTap,
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
            Text(
              emoji,
              style: AppTypography.glyph(
                32.sp,
                color: isLocked ? quizoo.tx3 : null,
              ),
            ),
            if (isPro)
              Positioned(
                top: 2.h,
                right: 2.w,
                child: Text('👑', style: AppTypography.glyph(11.sp)),
              ),
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
