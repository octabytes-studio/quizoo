import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_typography.dart';

/// The media plate above a question (S-15) — the one place every play
/// surface draws a question's photograph, pattern artwork, bundled asset or
/// emoji stand-in.
///
/// Lives in `core/` because all four play surfaces draw it: level play, the
/// daily challenge, the practice-bot duel and the live duel (CLAUDE.md §2).
///
/// **The fallback is the point**, and it is why this is stateful. The bible
/// states it as a hard requirement: "a failed image degrades to a text-only
/// question, never to a broken box". An `errorBuilder` alone cannot deliver
/// that — it can only replace the image's own subtree, leaving the plate's
/// reserved height and its gradient behind, which *is* the broken box. So a
/// remote/asset source is resolved up front and a failure collapses the
/// entire plate to nothing, letting the screen lay out as a text-only
/// question.
class QuestionMediaPlate extends StatefulWidget {
  const QuestionMediaPlate({
    super.key,
    this.figureSvg,
    this.mediaUrl,
    this.imageAsset,
    this.imageEmoji,
    this.colorFrom = '#2BB3FF',
    this.colorTo = '#7B4DFF',
    this.padding,
  });

  /// A pattern question's artwork (`questions.figure_svg`). Takes priority
  /// over every other source — the whole puzzle, including its own labelled
  /// options, lives inside this markup.
  final String? figureSvg;

  /// A hosted photograph (`questions.media_url`), drawn with `BoxFit.contain`
  /// so nothing the question depends on is ever cropped away.
  final String? mediaUrl;

  /// A bundled asset (mock/legacy image questions).
  final String? imageAsset;

  /// The emoji stand-in, shown when no artwork source can draw.
  final String? imageEmoji;

  /// Start of the plate's gradient, as `#RRGGBB`.
  final String colorFrom;

  /// End of the plate's gradient, as `#RRGGBB`.
  final String colorTo;

  /// Outer spacing. Defaults to play mode's `18 / 12 / 18 / 0` margins when
  /// null, so a collapsed plate leaves no gap behind.
  final EdgeInsetsGeometry? padding;

  /// `.qimg` — 132 tall.
  static const double height = 132;

  /// A pattern plate is taller than a photograph's: its artwork carries the
  /// whole puzzle and its four labelled options, so it is drawn at its own
  /// ~8:5 aspect within this box rather than squeezed into the 132px strip.
  static const double figureHeight = 210;

  @override
  State<QuestionMediaPlate> createState() => _QuestionMediaPlateState();
}

class _QuestionMediaPlateState extends State<QuestionMediaPlate> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _sourceFailed = false;

  String? get _figureSvg {
    final svg = widget.figureSvg;
    return svg == null || svg.trim().isEmpty ? null : svg;
  }

  /// The one remote source to draw, when there is one.
  String? get _url {
    final url = widget.mediaUrl;
    return url == null || url.isEmpty ? null : url;
  }

  /// The one bundled source to draw — only consulted when there is no URL,
  /// so a failed URL never silently swaps in an unrelated asset.
  String? get _asset {
    if (_url != null) return null;
    final asset = widget.imageAsset;
    return asset == null || asset.isEmpty ? null : asset;
  }

  String? get _emoji {
    final emoji = widget.imageEmoji;
    return emoji == null || emoji.isEmpty ? null : emoji;
  }

  /// True when there is nothing left to draw — no pattern, no working
  /// remote/asset source, and no emoji to fall back to.
  bool get _isEmpty {
    if (_figureSvg != null) return false;
    final hasSource = _url != null || _asset != null;
    return (!hasSource || _sourceFailed) && _emoji == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveSource();
  }

  @override
  void didUpdateWidget(QuestionMediaPlate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl ||
        oldWidget.imageAsset != widget.imageAsset) {
      _sourceFailed = false;
      _resolveSource();
    }
  }

  /// Resolves the remote/asset source up front, so its failure can collapse
  /// the whole plate (see the class doc).
  void _resolveSource() {
    _detach();
    final url = _url;
    final asset = _asset;
    if (url == null && asset == null) return;

    final ImageProvider<Object> provider = url != null
        ? NetworkImage(url)
        : AssetImage(asset!);
    final listener = ImageStreamListener(
      (_, _) {},
      onError: (error, stackTrace) {
        if (mounted) setState(() => _sourceFailed = true);
      },
    );
    _listener = listener;
    _stream = provider.resolve(createLocalImageConfiguration(context))
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

    final figureSvg = _figureSvg;
    final emoji = _emoji;
    final padding = widget.padding ?? EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0);

    final Widget plate;
    if (figureSvg != null) {
      plate = ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SvgPicture.string(
          figureSvg,
          width: double.infinity,
          height: QuestionMediaPlate.figureHeight.h,
          fit: BoxFit.contain,
          // A malformed artwork degrades to the plate's backdrop rather
          // than a red error box.
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    } else {
      final url = _url;
      final asset = _asset;
      plate = ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: QuestionMediaPlate.height.h,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.tileFromHex(
                widget.colorFrom,
                widget.colorTo,
              ),
            ),
            child: url != null && !_sourceFailed
                ? Image.network(url, fit: BoxFit.contain)
                : asset != null && !_sourceFailed
                ? Image.asset(asset, fit: BoxFit.contain)
                : Center(
                    child: Text(emoji!, style: AppTypography.glyph(60.sp)),
                  ),
          ),
        ),
      );
    }

    return Padding(padding: padding, child: plate);
  }
}
