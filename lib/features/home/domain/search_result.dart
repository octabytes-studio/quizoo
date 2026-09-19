import 'package:equatable/equatable.dart';
import 'package:quizoo/core/models/subcategory.dart';

/// One S-06 result row: a matched topic plus its parent category's own name.
///
/// Not a `@freezed` model like [HomeContent]'s pieces — it holds no state of
/// its own and is never persisted or sent over the wire (matches
/// `HomeCategorySection`'s reasoning). Carried as a pair because
/// [Subcategory] has no name for its own category, and the breadcrumb needs
/// one resolved against the same real, language-scoped rows the match itself
/// came from, not `MockCatalog`'s fixed ids.
class SearchResult extends Equatable {
  const SearchResult({required this.subcategory, required this.categoryName});

  final Subcategory subcategory;
  final String categoryName;

  @override
  List<Object?> get props => [subcategory, categoryName];
}
