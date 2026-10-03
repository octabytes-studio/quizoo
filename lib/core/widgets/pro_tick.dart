import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The gold verified tick that follows a Pro member's name (plan 023).
///
/// A semantic label of its own — it is never part of the name's own text, so
/// a screen reader announces "Waleed, Pro member" rather than running the two
/// together. Colour comes from the themed gold token (design bible §04: mint
/// and raspberry communicate correctness only — the Pro badge is gold).
class ProTick extends StatelessWidget {
  const ProTick({super.key, this.size});

  /// Defaults to a size that sits comfortably beside `titleSmall`. Pass a
  /// smaller value where the name is already small.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 16;
    return Semantics(
      label: AppLocalizations.of(context).proBadgeLabel,
      child: ExcludeSemantics(
        child: Icon(
          Icons.verified_rounded,
          size: dimension,
          color: context.quizoo.gold,
        ),
      ),
    );
  }
}
