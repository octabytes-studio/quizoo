import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// A debug-only index of all 54 screens in the design bible.
///
/// This is the "temporary debug list" plan 001 names as the way every reserved
/// route stays reachable while its real body is still a placeholder. It has no
/// route into it from any product surface — only the ☰ affordance on a
/// placeholder screen — and it comes out when the last placeholder does.
class ScreenIndexScreen extends StatelessWidget {
  const ScreenIndexScreen({super.key});

  /// Substitutes a demo value for each dynamic segment so a tap actually
  /// navigates rather than landing on a literal `:categoryId`.
  static String resolve(String path) => path
      .replaceAll(':categoryId', 'demo-category')
      .replaceAll(':subcategoryId', 'demo-subcategory')
      .replaceAll(':levelNumber', '8')
      .replaceAll(':levelId', 'demo')
      .replaceAll(':duelId', 'demo-duel')
      .replaceAll(':badgeId', 'demo-badge');

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin.w,
                AppSpacing.md.h,
                AppSpacing.screenMargin.w,
                AppSpacing.md.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.devScreenIndexTitle, style: textTheme.titleLarge),
                    Text(
                      l10n.devScreenIndexSubtitle,
                      style: textTheme.labelSmall!.copyWith(
                        fontFamily: AppTypography.mono,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final entry in _grouped.entries) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin.w,
                  AppSpacing.md.h,
                  AppSpacing.screenMargin.w,
                  AppSpacing.sm.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(entry.key, style: textTheme.titleMedium),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin.w,
                ),
                sliver: SliverList.separated(
                  itemCount: entry.value.length,
                  separatorBuilder: (_, _) => SizedBox(height: 9.h),
                  itemBuilder: (context, index) {
                    final screen = entry.value[index];
                    return ListRowTile(
                      title: '${screen.id}  ${screen.name}',
                      subtitle: screen.path,
                      trailing: AppChip.status(label: screen.plan),
                      onTap: () => context.push(resolve(screen.path)),
                    );
                  },
                ),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl.h)),
          ],
        ),
      ),
    );
  }

  /// The bible's own grouping, rebuilt from [kScreenIndex] so the two cannot
  /// drift apart.
  static Map<String, List<ScreenRef>> get _grouped {
    final grouped = <String, List<ScreenRef>>{};
    var currentGroup = '';
    for (final screen in kScreenIndex) {
      if (screen.group.isNotEmpty) currentGroup = screen.group;
      grouped.putIfAbsent(currentGroup, () => []).add(screen);
    }
    return grouped;
  }
}
