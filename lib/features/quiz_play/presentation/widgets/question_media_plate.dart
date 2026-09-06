import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// `.qimg` — the 132px media plate above an image question (S-15).
///
/// **The fallback is the point**, and it is why this is stateful. The bible
/// states it as a hard requirement: "a failed image degrades to a text-only
/// question, never to a broken box". An `errorBuilder` alone cannot deliver
/// that — it can only replace the image's own subtree, leaving the 132px of
/// reserved height and its gradient behind, which *is* the broken box. So the
/// asset is resolved up front and a failure collapses the entire plate to
/// nothing, letting the screen lay out as a text-only question.
class QuestionMediaPlate extends StatefulWidget {
  const QuestionMediaPlate({required this.question, super.key});

  final Question question;

  /// `.qimg` — 132 tall.
  static const double height = 132;

  @override
  State<QuestionMediaPlate> createState() => _QuestionMediaPlateState();
}

class _QuestionMediaPlateState extends State<QuestionMediaPlate> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _assetFailed = false;

  String? get _asset => widget.question.imageAsset;

  String? get _emoji {
    final emoji = widget.question.imageEmoji;
    return emoji == null || emoji.isEmpty ? null : emoji;
  }

  /// True when there is nothing left to draw — no working asset and no emoji
  /// to fall back to.
  bool get _isEmpty =>
      !widget.question.hasImage ||
      ((_asset == null || _assetFailed) && _emoji == null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAsset();
  }

  @override
  void didUpdateWidget(QuestionMediaPlate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.imageAsset != _asset) {
      _assetFailed = false;
      _resolveAsset();
    }
  }

  void _resolveAsset() {
    _detach();
    final asset = _asset;
    if (asset == null) return;

    final listener = ImageStreamListener(
      (_, _) {},
      onError: (error, stackTrace) {
        if (mounted) setState(() => _assetFailed = true);
      },
    );
    _listener = listener;
    _stream = AssetImage(asset).resolve(createLocalImageConfiguration(context))
      ..addListener(listener);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) return const SizedBox.shrink();

    final asset = _asset;
    final emoji = _emoji;

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: QuestionMediaPlate.height.h,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.tileFromHex(
                widget.question.imageColorFrom,
                widget.question.imageColorTo,
              ),
            ),
            child: asset == null || _assetFailed
                ? Center(child: Text(emoji!, style: AppTypography.glyph(60.sp)))
                : Image.asset(asset, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
