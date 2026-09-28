import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// A guest nudge shown wherever real data is already on screen (the
/// player's anonymous session is a real Supabase identity): an invitation to
/// turn that into a permanent account, not a gate. Shared between S-32
/// (`ProfileScreen`) and Edit Profile rather than duplicated. The sign-in
/// button renders explicitly below the copy rather than relying on the whole
/// card being silently tappable, so the CTA reads as a CTA.
class GuestSignInBanner extends StatelessWidget {
  const GuestSignInBanner({super.key});

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
