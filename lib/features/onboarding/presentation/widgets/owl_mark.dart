import 'package:flutter/material.dart';

/// Quizoo's owl, drawn rather than shipped as an asset.
///
/// It is a dozen circles and triangles in a 100×100 space — transcribed from
/// the `<svg>` in the design bible's S-01 frame — so a [CustomPainter] is both
/// smaller than a bundled asset and sharp at any size the splash animation
/// scales it to.
class OwlMark extends StatelessWidget {
  const OwlMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _OwlPainter(),
        // The mark is decorative — the wordmark beside it carries the name.
        isComplex: false,
      ),
    );
  }
}

class _OwlPainter extends CustomPainter {
  const _OwlPainter();

  /// The SVG's own coordinate space, which every value below is written in.
  static const double _viewBox = 100;

  static const Color _body = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFFEDE8FA);
  static const Color _eye = Color(0xFF7B4DFF);
  static const Color _beak = Color(0xFFFF8A24);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewBox;
    canvas
      ..save()
      ..scale(scale);

    final paint = Paint()..isAntiAlias = true;

    void ellipse(double cx, double cy, double rx, double ry, Color color) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        paint..color = color,
      );
    }

    void triangle(List<Offset> points, Color color) {
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, paint..color = color);
    }

    // Ears, behind the head.
    triangle(const [Offset(18, 34), Offset(26, 10), Offset(42, 26)], _accent);
    triangle(const [Offset(82, 34), Offset(74, 10), Offset(58, 26)], _accent);

    ellipse(50, 56, 35, 34, _body);
    ellipse(50, 70, 21, 18, _accent);

    // Eyes: a wide iris with an offset highlight, which is what gives the
    // mark its face.
    ellipse(36, 47, 14, 14, _eye);
    ellipse(64, 47, 14, 14, _eye);
    ellipse(38, 48, 6.5, 6.5, _body);
    ellipse(62, 48, 6.5, 6.5, _body);

    triangle(const [Offset(50, 56), Offset(44, 62), Offset(56, 62)], _beak);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_OwlPainter oldDelegate) => false;
}
