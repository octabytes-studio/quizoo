import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The segmented control — Global / Country / Friends, Weekly / Monthly /
/// All-time.
///
/// `.tabsel`: a 4px-inset thumb on a sunken track, which is what separates it
/// visually from the pill-shaped [AppChip] row that often sits right below it.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  /// Two or more segment labels, in display order.
  final List<String> labels;

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xs.w),
      decoration: BoxDecoration(
        color: quizoo.s3,
        borderRadius: BorderRadius.circular(AppRadius.segmentedTrack.r),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed) ...[
            if (index > 0) SizedBox(width: AppSpacing.xs.w),
            Expanded(
              child: Semantics(
                button: true,
                selected: index == selectedIndex,
                label: label,
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == selectedIndex
                          ? quizoo.s1
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppRadius.segmentedThumb.r,
                      ),
                      boxShadow: index == selectedIndex ? quizoo.shadow : null,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge!.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: index == selectedIndex ? quizoo.tx : quizoo.tx2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
