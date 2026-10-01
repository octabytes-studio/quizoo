import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/ads/inline_ad_layout.dart';

void main() {
  group('interleaveAdRows', () {
    // (itemCount, firstAfter, every, max) → rows; null is an ad row.
    final cases =
        <({int items, int first, int every, int max, List<int?> rows})>[
          (items: 0, first: 2, every: 5, max: 2, rows: []),
          (items: 2, first: 2, every: 5, max: 2, rows: [0, 1]),
          (items: 3, first: 2, every: 5, max: 2, rows: [0, 1, null, 2]),
          (
            items: 7,
            first: 2,
            every: 5,
            max: 2,
            rows: [0, 1, null, 2, 3, 4, 5, 6],
          ),
          (
            items: 8,
            first: 2,
            every: 5,
            max: 2,
            rows: [0, 1, null, 2, 3, 4, 5, 6, null, 7],
          ),
          (
            items: 14,
            first: 2,
            every: 5,
            max: 2,
            rows: [0, 1, null, 2, 3, 4, 5, 6, null, 7, 8, 9, 10, 11, 12, 13],
          ),
          (
            items: 8,
            first: 2,
            every: 5,
            max: 1,
            rows: [0, 1, null, 2, 3, 4, 5, 6, 7],
          ),
          (items: 5, first: 2, every: 5, max: 0, rows: [0, 1, 2, 3, 4]),
          (items: 5, first: 0, every: 2, max: 2, rows: [0, 1, 2, 3, 4]),
          (items: 4, first: 1, every: 0, max: 3, rows: [0, null, 1, 2, 3]),
          (
            items: 4,
            first: 1,
            every: 1,
            max: 2,
            rows: [0, null, 1, null, 2, 3],
          ),
        ];

    for (final c in cases) {
      test('${c.items} items, first after ${c.first}, every ${c.every}, '
          'max ${c.max}', () {
        final rows = interleaveAdRows(
          itemCount: c.items,
          firstAfter: c.first,
          every: c.every,
          max: c.max,
        );

        expect(rows, c.rows);
        if (rows.isNotEmpty) {
          expect(rows.first, isNotNull, reason: 'never starts on an ad');
          expect(rows.last, isNotNull, reason: 'never ends on an ad');
        }
        expect(rows.nonNulls.toList(), List.generate(c.items, (i) => i));
      });
    }
  });
}
