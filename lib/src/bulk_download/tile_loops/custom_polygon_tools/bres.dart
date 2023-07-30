import 'dart:math';

/// Bresenham’s Line Generation Algorithm
Iterable<Point<int>> bresenhamLGA(Point<int> start, Point<int> end) sync* {
  var x1 = start.x;
  var x2 = end.x;
  var y1 = start.y;
  var y2 = end.y;

  var x = x1;
  var y = y1;

  var dx = (x2 - x1).abs();
  var dy = (y2 - y1).abs();

  if (dy / dx > 1) {
    final intermediateDx = dx;
    dx = dy;
    dy = intermediateDx;

    final intermediateX = x;
    x = y;
    y = intermediateX;

    final intermediateX1 = x1;
    x1 = y1;
    y1 = intermediateX1;

    final intermediateX2 = x2;
    x2 = y2;
    y2 = intermediateX2;
  }

  var p = 2 * dy - dx;

  yield Point(x, y);

  for (int k = 2; k < dx + 2; k++) {
    if (p > 0) {
      y += y < y2 ? 1 : -1;
      p += 2 * (dy - dx);
    } else {
      p += 2 * dy;
    }

    x += x < x2 ? 1 : -1;

    yield Point(x, y);
  }
}
