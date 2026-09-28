import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_quit_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The duel HUD's speaker toggle — question read-aloud and sound effects on
/// or off for this player, the same 🔊 / 🔇 control (and the same persisted
/// preference) as play mode's HUD.
class DuelAudioButton extends StatelessWidget {
  const DuelAudioButton({
    required this.isOn,
    required this.onPressed,
    super.key,
  });

  final bool isOn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      toggled: isOn,
      label: isOn ? l10n.quizAudioOnLabel : l10n.quizAudioOffLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: DuelQuitButton.size.w,
          height: DuelQuitButton.size.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: arena.chrome,
            borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
          ),
          child: ExcludeSemantics(
            child: Text(isOn ? '🔊' : '🔇', style: AppTypography.glyph(15.sp)),
          ),
        ),
      ),
    );
  }
}
