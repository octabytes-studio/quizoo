import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/duel/data/duel_arena_api.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_topic_picker_cubit.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_topic_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Why the topic picker was opened — selects its title copy.
enum DuelTopicPurpose { create, matchmake }

/// The "pick your battleground" bottom sheet (plan 017): picking a
/// sub-category is required both to create a challenge and to matchmake.
///
/// Only topics with enough live questions in the player's content language
/// are offered, grouped by category in the server's order (topics with
/// activity first inside each category). Pops with the chosen [DuelTopic].
class DuelTopicPickerSheet extends StatelessWidget {
  const DuelTopicPickerSheet({required this.purpose, super.key});

  final DuelTopicPurpose purpose;

  /// Opens the sheet; completes with the picked topic, or null if dismissed.
  ///
  /// The sheet brings its own [DuelTopicPickerCubit], built from the
  /// app-root [DuelRealtime] + [ServerClock] and the picked content
  /// language.
  static Future<DuelTopic?> show(
    BuildContext context, {
    required DuelTopicPurpose purpose,
  }) {
    final repository = DuelArenaRepository(
      DuelArenaApi(supabase, context.read<DuelRealtime>()),
      context.read<ServerClock>(),
    );
    final languageCode = context.read<ContentLanguageCubit>().state.code;

    return AppBottomSheet.show<DuelTopic>(
      context,
      builder: (_) => BlocProvider<DuelTopicPickerCubit>(
        create: (_) => DuelTopicPickerCubit(repository)..load(languageCode),
        child: DuelTopicPickerSheet(purpose: purpose),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBottomSheet(
      title: switch (purpose) {
        DuelTopicPurpose.create => l10n.duelPickerTitleCreate,
        DuelTopicPurpose.matchmake => l10n.duelPickerTitleMatch,
      },
      message: l10n.duelPickerBody,
      child: BlocBuilder<DuelTopicPickerCubit, DuelTopicPickerState>(
        builder: (context, state) => switch (state) {
          DuelTopicPickerLoading() => const _TopicSkeleton(),
          DuelTopicPickerFailed(:final error) => ErrorStateView(
            title: l10n.contentErrorTitle,
            emoji: '🗺️',
            message: l10n.contentErrorBody,
            errorCode: error.code,
            action: ChunkyButton.ghost(
              label: l10n.commonRetry,
              onPressed: () => context.read<DuelTopicPickerCubit>().retry(),
            ),
          ),
          DuelTopicPickerLoaded(:final topics) when topics.isEmpty =>
            EmptyStateView(emoji: '🌐', title: l10n.duelPickerEmpty),
          DuelTopicPickerLoaded(:final topics) => _TopicList(topics: topics),
        },
      ),
    );
  }
}

/// Topics grouped under their category, in the server's order.
class _TopicList extends StatelessWidget {
  const _TopicList({required this.topics});

  final List<DuelTopic> topics;

  @override
  Widget build(BuildContext context) {
    // Group by category, keeping first-appearance order for both the
    // categories and the rows inside them — the server already sorted both.
    final groups = <String, List<DuelTopic>>{};
    for (final topic in topics) {
      final key = topic.categoryId.isEmpty
          ? topic.categoryName
          : topic.categoryId;
      groups.putIfAbsent(key, () => []).add(topic);
    }

    return ListView(
      shrinkWrap: true,
      children: [
        for (final group in groups.values) ...[
          _CategoryHeader(topic: group.first),
          for (final topic in group)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: DuelTopicRow(
                topic: topic,
                onTap: () => Navigator.of(context).pop(topic),
              ),
            ),
          SizedBox(height: AppSpacing.sm.h),
        ],
      ],
    );
  }
}

/// "⚽ Sports" above a category's rows.
///
/// Not the app-wide `SectionHeader`: that one bakes in the 20px screen
/// margin, which the sheet already applies, so its title would sit indented
/// from the rows below it.
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.topic});

  final DuelTopic topic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(topic.categoryEmoji, style: AppTypography.glyph(16.sp)),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Text(
                topic.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row-shaped shimmer while the topics load.
class _TopicSkeleton extends StatelessWidget {
  const _TopicSkeleton();

  static const int rows = 5;
  static const double rowHeight = 66;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
            child: SkeletonBox(
              height: rowHeight.h,
              borderRadius: BorderRadius.circular(AppRadius.listRow.r),
            ),
          ),
      ],
    );
  }
}
