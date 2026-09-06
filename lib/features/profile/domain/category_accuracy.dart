import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_accuracy.freezed.dart';
part 'category_accuracy.g.dart';

/// One row of S-35's "Accuracy by category" list.
@freezed
abstract class CategoryAccuracy with _$CategoryAccuracy {
  const factory CategoryAccuracy({
    required String categoryName,
    required String emoji,
    required int accuracyPercent,
  }) = _CategoryAccuracy;

  factory CategoryAccuracy.fromJson(Map<String, dynamic> json) =>
      _$CategoryAccuracyFromJson(json);
}
