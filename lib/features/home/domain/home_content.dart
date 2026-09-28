import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/player_currency.dart';
import 'package:quizoo/core/models/subcategory.dart';

part 'home_content.freezed.dart';
part 'home_content.g.dart';

/// A card in Home's "Popular this week" rail (`.pq`).
///
/// It carries its own gradient because the rail is a merchandising surface —
/// the bible's own frames show a card whose colours are not its category's,
/// and those come from content rather than from the taxonomy.
@freezed
abstract class PopularQuiz with _$PopularQuiz {
  const factory PopularQuiz({
    required String id,

    /// The topic tapping the card opens.
    required String subcategoryId,
    required String title,
    required String emoji,

    /// Start of the card's 150° gradient, as `#RRGGBB`.
    required String colorFrom,

    /// End of the card's gradient.
    required String colorTo,

    /// Plays this week, rendered compactly as "84.2k played".
    @Default(0) int playedCount,

    /// Wears the raspberry "HOT" badge.
    @Default(false) bool isHot,
  }) = _PopularQuiz;

  factory PopularQuiz.fromJson(Map<String, dynamic> json) =>
      _$PopularQuizFromJson(json);
}

/// The unfinished level behind Home's Continue rail.
///
/// The bible calls this "the highest-converting row on the screen", and it is
/// nullable for a reason: the rail is absent entirely when there is nothing in
/// progress, never present-but-empty.
@freezed
abstract class ContinueEntry with _$ContinueEntry {
  const factory ContinueEntry({
    required String subcategoryId,
    required String subcategoryName,
    required String emoji,

    /// Tint behind the emoji plate, as `#RRGGBB`.
    required String plateColor,
    required int levelNumber,
    @Default(0) int points,
    @Default(3) int livesLeft,
  }) = _ContinueEntry;

  factory ContinueEntry.fromJson(Map<String, dynamic> json) =>
      _$ContinueEntryFromJson(json);
}

/// The daily-challenge banner's preview data (the tab itself is plan 003).
@freezed
abstract class DailyChallengePreview with _$DailyChallengePreview {
  const factory DailyChallengePreview({
    @Default(10) int questionCount,

    /// Minutes until today's challenge closes, so the banner can render
    /// "ends in 4h 12m" without holding a live clock.
    @Default(0) int minutesRemaining,
  }) = _DailyChallengePreview;

  const DailyChallengePreview._();

  factory DailyChallengePreview.fromJson(Map<String, dynamic> json) =>
      _$DailyChallengePreviewFromJson(json);

  Duration get remaining => Duration(minutes: minutesRemaining);
}

/// Everything Home renders, in one object.
///
/// Home has two layouts, not two screens (S-04 guest, S-05 signed-in), so one
/// model serves both and the fields a guest has nothing to put in are simply
/// empty: no wallet, no [continueEntry], no [daily].
@freezed
abstract class HomeContent with _$HomeContent {
  const factory HomeContent({
    @Default([]) List<Category> categories,
    @Default([]) List<Subcategory> subcategories,
    @Default([]) List<PopularQuiz> popular,
    ContinueEntry? continueEntry,
    DailyChallengePreview? daily,

    /// Null for a guest, which is what removes the wallet pills from the top
    /// bar — the bible is explicit that a guest has earned nothing yet.
    PlayerCurrency? currency,

    /// The signed-in player's real `profiles.streak_days`/`player_level`
    /// (plan 019) — 0 for a guest, and 0 in `_HomeSkeleton`'s pre-fetch
    /// flash, which has no [HomeContent] to read yet.
    @Default(0) int dayStreak,
    @Default(0) int playerLevel,
  }) = _HomeContent;

  const HomeContent._();

  factory HomeContent.fromJson(Map<String, dynamic> json) =>
      _$HomeContentFromJson(json);

  /// One section per category with at least one topic (plan 009) — a
  /// category with none is dropped entirely rather than rendered as an empty
  /// rail. Order is state-driven (assumption 1 of that plan): the category
  /// owning [continueEntry]'s topic is promoted first, everything else
  /// follows [Category.order].
  List<HomeCategorySection> get sections {
    final topicsByCategory = <String, List<Subcategory>>{};
    for (final subcategory in subcategories) {
      (topicsByCategory[subcategory.categoryId] ??= []).add(subcategory);
    }

    String? promotedCategoryId;
    if (continueEntry case final entry?) {
      for (final subcategory in subcategories) {
        if (subcategory.id == entry.subcategoryId) {
          promotedCategoryId = subcategory.categoryId;
          break;
        }
      }
    }

    final ordered = [...categories]
      ..sort((a, b) {
        if (a.id == promotedCategoryId) return -1;
        if (b.id == promotedCategoryId) return 1;
        return a.order.compareTo(b.order);
      });

    return [
      for (final category in ordered)
        if (topicsByCategory[category.id] case final topics?
            when topics.isNotEmpty)
          HomeCategorySection(category: category, topics: topics),
    ];
  }
}

/// One category and its topics, in the order [HomeContent.sections] decided.
///
/// Not a `@freezed` model like the rest of this file: it holds no state of
/// its own, is never persisted or sent over the wire, and is recomputed on
/// every read of [HomeContent.sections].
class HomeCategorySection extends Equatable {
  const HomeCategorySection({required this.category, required this.topics});

  final Category category;
  final List<Subcategory> topics;

  @override
  List<Object?> get props => [category, topics];
}
