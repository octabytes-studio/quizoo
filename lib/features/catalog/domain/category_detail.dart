import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/subcategory.dart';

part 'category_detail.freezed.dart';
part 'category_detail.g.dart';

/// How S-07's topic grid is ordered.
///
/// The bible offers three; only [popular] is wired in this phase, and the
/// control says "Sort: Popular" rather than pretending the others work.
enum TopicSort { popular, alphabetical, progress }

/// Everything S-07 renders: the category, its topics, and the player count
/// its header quotes.
@freezed
abstract class CategoryDetail with _$CategoryDetail {
  const factory CategoryDetail({
    required Category category,
    @Default([]) List<Subcategory> topics,

    /// The "128k players" half of the header meta line. It is not on
    /// [Category] because it is a live engagement figure, not taxonomy.
    @Default(0) int playerCount,

    /// Total stars across every topic in this category — the header's ⭐
    /// stat chip (plan 009). The rank chip alongside it is a follow-up
    /// (plan 009, open question 4): a category leaderboard read this phase
    /// does not add.
    @Default(0) int starsEarned,

    /// Total levels cleared across every topic — the header's 🏁 stat chip.
    @Default(0) int levelsCleared,

    /// "Pick up where you left" — the topic in this category the player is
    /// currently on (plan 009, assumption 5). Null when nothing in the
    /// category has been started, which is when the resume card is absent
    /// entirely rather than an empty shell.
    Subcategory? resumeTopic,
  }) = _CategoryDetail;

  factory CategoryDetail.fromJson(Map<String, dynamic> json) =>
      _$CategoryDetailFromJson(json);
}
