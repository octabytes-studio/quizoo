/// Feed rows for [itemCount] content items with ads interleaved: each entry
/// is a content index, or null for an ad row.
///
/// The first ad row comes after [firstAfter] items, then one per [every]
/// items, up to [max]. A feed never starts or ends on an ad, and one too short
/// to reach [firstAfter] gets none.
List<int?> interleaveAdRows({
  required int itemCount,
  required int firstAfter,
  required int every,
  required int max,
}) {
  final rows = <int?>[];
  var ads = 0;
  for (var index = 0; index < itemCount; index++) {
    final passed = index - firstAfter;
    final isAdPosition =
        firstAfter > 0 &&
        passed >= 0 &&
        (every < 1 ? passed == 0 : passed % every == 0);
    if (isAdPosition && ads < max) {
      rows.add(null);
      ads++;
    }
    rows.add(index);
  }
  return rows;
}
