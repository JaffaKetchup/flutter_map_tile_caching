import 'package:flutter/widgets.dart';

class BubbleArrowIndicator extends CustomPainter {
  const BubbleArrowIndicator({
    this.borderRadius = BorderRadius.zero,
    this.triangleSize = const Size(25, 10),
    this.color,
  });

  final BorderRadius borderRadius;
  final Size triangleSize;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? const Color(0xFF000000)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    canvas
      ..drawPath(
        Path()
          ..moveTo(size.width / 2 - triangleSize.width / 2, size.height)
          ..lineTo(size.width / 2, triangleSize.height + size.height)
          ..lineTo(size.width / 2 + triangleSize.width / 2, size.height)
          ..lineTo(size.width / 2 - triangleSize.width / 2, size.height),
        paint,
      )
      ..drawRRect(
        borderRadius.toRRect(Rect.fromLTRB(0, 0, size.width, size.height)),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
