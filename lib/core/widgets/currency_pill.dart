import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The three wallet currencies, each with its own token disc.
enum CurrencyKind {
  /// 🪙 Lemon. Buys power-ups.
  coin,

  /// 💎 Sky. Premium.
  gem,

  /// ❤️ Raspberry. Spent on a failed level.
  life,
}

/// A wallet pill from the top bar.
///
/// Each carries a coloured token disc "so the value is scannable without
/// reading" (§06) — the disc gradient is fixed per currency and does not
/// change with the theme.
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({
    required this.kind,
    required this.value,
    super.key,
    this.onTap,
  });

  final CurrencyKind kind;

  /// Already formatted — "1,240", "18", "4/5".
  final String value;

  final VoidCallback? onTap;

  /// `.pill .o` — the token disc.
  static const double discSize = 21;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    final (String glyph, Color from, Color to) = switch (kind) {
      CurrencyKind.coin => ('🪙', AppColors.coinDiscFrom, AppColors.coinDiscTo),
      CurrencyKind.gem => ('💎', AppColors.gemDiscFrom, AppColors.gemDiscTo),
      CurrencyKind.life => ('❤️', AppColors.lifeDiscFrom, AppColors.lifeDiscTo),
    };

    return Semantics(
      button: onTap != null,
      label: '${kind.name} $value',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.fromLTRB(AppSpacing.xs.w + 2, 5.h, 11.w, 5.h),
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: quizoo.ln),
            boxShadow: quizoo.shadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: discSize.w,
                height: discSize.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    // `linear-gradient(160deg, …)` — a shallow diagonal.
                    begin: const Alignment(-0.64, -1),
                    end: const Alignment(0.64, 1),
                    colors: [from, to],
                  ),
                ),
                child: Text(glyph, style: AppTypography.glyph(12.sp)),
              ),
              SizedBox(width: 5.w),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: quizoo.tx,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
