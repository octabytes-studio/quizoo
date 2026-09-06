import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-17 — the pause sheet.
///
/// Sound and haptics are toggleable here "because this is where people reach
/// when a phone gets loud at the wrong moment". Both are **recorded but
/// inert** in this phase: no audio and no `HapticFeedback` is wired at all
/// (plan 002, Scope), so the toggles change a preference and nothing else.
class PauseSheet extends StatelessWidget {
  const PauseSheet({
    required this.isSoundOn,
    required this.isHapticsOn,
    required this.onResume,
    required this.onToggleSound,
    required this.onToggleHaptics,
    required this.onRestart,
    required this.onQuit,
    super.key,
  });

  final bool isSoundOn;
  final bool isHapticsOn;
  final VoidCallback onResume;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleHaptics;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return AppBottomSheet(
      title: l10n.pauseTitle,
      message: l10n.pauseBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChunkyButton(label: l10n.pauseResume, onPressed: onResume),
          SizedBox(height: 9.h),
          Row(
            children: [
              Expanded(
                child: ChunkyButton.ghost(
                  label: isSoundOn ? l10n.pauseSoundOn : l10n.pauseSoundOff,
                  isSmall: true,
                  onPressed: onToggleSound,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: ChunkyButton.ghost(
                  label: isHapticsOn
                      ? l10n.pauseHapticsOn
                      : l10n.pauseHapticsOff,
                  isSmall: true,
                  onPressed: onToggleHaptics,
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          ChunkyButton.line(label: l10n.pauseRestart, onPressed: onRestart),
          SizedBox(height: 9.h),
          // The destructive line item is raspberry-tinted and listed last.
          Theme(
            data: Theme.of(context).copyWith(
              extensions: [quizoo.copyWith(tx2: quizoo.bad, ln: quizoo.bad)],
            ),
            child: ChunkyButton.line(label: l10n.pauseQuit, onPressed: onQuit),
          ),
          SizedBox(height: AppSpacing.sm.h),
        ],
      ),
    );
  }
}
