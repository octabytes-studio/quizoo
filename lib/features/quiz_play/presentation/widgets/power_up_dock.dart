import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/power_up_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.pups` — the three power-up tiles under the options.
///
/// The lemon ring on `+15s` is the bible's one deliberate nudge toward
/// spending, and it appears only in the danger window and only when the
/// player already owns one — never as an upsell to someone with none.
class PowerUpDock extends StatelessWidget {
  const PowerUpDock({
    required this.inventory,
    required this.isDanger,
    required this.onUse,
    required this.onBuy,
    super.key,
  });

  final PowerUpInventory inventory;
  final bool isDanger;
  final ValueChanged<PowerUp> onUse;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    final tiles = <(PowerUp, String, String)>[
      (PowerUp.fiftyFifty, '🎯', l10n.quizPowerUpFiftyFifty),
      (PowerUp.addTime, '⏱️', l10n.quizPowerUpAddTime),
      (PowerUp.skip, '⏭️', l10n.quizPowerUpSkip),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (powerUp, emoji, label) in tiles)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.powerUp.r),
                  border: _highlights(powerUp)
                      ? Border.all(color: quizoo.gold, width: 2)
                      : null,
                ),
                child: PowerUpTile(
                  emoji: emoji,
                  label: label,
                  count: inventory.countOf(powerUp),
                  onUse: () => onUse(powerUp),
                  onBuy: onBuy,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _highlights(PowerUp powerUp) =>
      isDanger && powerUp == PowerUp.addTime && inventory.has(powerUp);
}
