import 'package:flutter/widgets.dart';

class SideIndicatorPainter extends CustomPainter {
  const SideIndicatorPainter({
    this.startRadius = Radius.zero,
    this.endRadius = Radius.zero,
    this.color,
  });

  final Radius startRadius;
  final Radius endRadius;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
        Path()
          ..moveTo(0, size.height / 2)
          ..lineTo((size.height / 2) - startRadius.x, startRadius.y)
          ..quadraticBezierTo(
            size.height / 2,
            0,
            (size.height / 2) + startRadius.x,
            0,
          )
          ..lineTo(size.width - endRadius.x, 0)
          ..arcToPoint(
            Offset(size.width, endRadius.y),
            radius: endRadius,
          )
          ..lineTo(size.width, size.height - endRadius.y)
          ..arcToPoint(
            Offset(size.width - endRadius.x, size.height),
            radius: endRadius,
          )
          ..lineTo((size.height / 2) + startRadius.x, size.height)
          ..quadraticBezierTo(
            size.height / 2,
            size.height,
            (size.height / 2) - startRadius.x,
            size.height - startRadius.y,
          )
          ..lineTo(0, size.height / 2)
          ..close(),
        Paint()
          ..color = color ?? const Color(0xFF000000)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill,
      );

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
