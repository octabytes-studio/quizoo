import 'package:flutter/material.dart';
import 'package:quizoo/core/widgets/pro_tick.dart';

/// A player's name with the Pro tick after it (plan 023).
///
/// The name is `Flexible` with ellipsis so a long one truncates and the tick
/// always remains visible — the badge is the point of the widget. The tick
/// carries its own semantics label ([ProTick]), and the name is its own
/// `Text`, so a screen reader reads "name, Pro member" rather than a run-on.
class ProName extends StatelessWidget {
  const ProName({
    required this.name,
    required this.isPro,
    super.key,
    this.style,
    this.maxLines = 1,
    this.tickSize,
    this.textAlign,
  });

  final String name;
  final bool isPro;
  final TextStyle? style;
  final int maxLines;

  /// Alignment of the name within the row. The tick always trails it, so a
  /// centred name still reads as "name ✓".
  final TextAlign? textAlign;

  /// Passed through to [ProTick]; defaults to a size matched to [style].
  final double? tickSize;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? Theme.of(context).textTheme.titleSmall!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: textAlign == TextAlign.center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            name,
            style: resolvedStyle,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          ),
        ),
        if (isPro) ...[
          SizedBox(width: resolvedStyle.fontSize! * 0.22),
          ProTick(size: tickSize ?? resolvedStyle.fontSize! * 1.05),
        ],
      ],
    );
  }
}
