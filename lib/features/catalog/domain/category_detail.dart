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
  }) = _CategoryDetail;

  factory CategoryDetail.fromJson(Map<String, dynamic> json) =>
      _$CategoryDetailFromJson(json);
}
