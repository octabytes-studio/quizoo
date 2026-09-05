import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';

/// S-51 — the report-a-question sheet.
///
/// A single-select list of reasons on the standard list row, with the chosen
/// row taking a 2px grape border and a filled radio glyph. Reachable from the
/// ⋯ on any question and from a result screen's review list, which is why it
/// lives in `core/` (plan 001, Assumption 6).
///
/// This widget owns only its selection — genuinely ephemeral, local UI state
/// with no business meaning, which is the one thing `setState` is for
/// (CLAUDE.md §3). What happens to the report is the caller's problem.
class ReportQuestionSheet extends StatefulWidget {
  const ReportQuestionSheet({
    required this.title,
    required this.reasons,
    required this.onSubmit,
    required this.submitLabel,
    super.key,
    this.message,
  });

  final String title;

  /// "Question 6 · Football · Level 12. Thanks — we review every report
  /// within 48 hours."
  final String? message;

  /// The selectable reasons, in display order.
  final List<String> reasons;

  final String submitLabel;

  /// Receives the index of the chosen reason.
  final ValueChanged<int> onSubmit;

  @override
  State<ReportQuestionSheet> createState() => _ReportQuestionSheetState();
}

class _ReportQuestionSheetState extends State<ReportQuestionSheet> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return AppBottomSheet(
      title: widget.title,
      message: widget.message,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, reason) in widget.reasons.indexed) ...[
              if (index > 0) SizedBox(height: 9.h),
              ListRowTile(
                title: reason,
                padding: EdgeInsets.all(13.w),
                accentColor: _selectedIndex == index ? quizoo.g : null,
                trailing: Text(
                  _selectedIndex == index ? '●' : '○',
                  style: AppTypography.glyph(
                    14.sp,
                    color: _selectedIndex == index ? quizoo.g : quizoo.tx3,
                  ),
                ),
                onTap: () => setState(() => _selectedIndex = index),
              ),
            ],
            SizedBox(height: 14.h),
            ChunkyButton(
              label: widget.submitLabel,
              onPressed: _selectedIndex == null
                  ? null
                  : () => widget.onSubmit(_selectedIndex!),
            ),
            SizedBox(height: AppSpacing.xs.h),
          ],
        ),
      ),
    );
  }
}
