import 'dart:math';

/// Bresenham’s line generation algorithm, ported from
/// [anushaihalapathirana/Bresenham-line-drawing-algorithm](https://github.com/anushaihalapathirana/Bresenham-line-drawing-algorithm).
Iterable<Point<int>> bresenhamsLGA(Point<int> start, Point<int> end) sync* {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final absdx = dx.abs();
  final absdy = dy.abs();

  var x = start.x;
  var y = start.y;
  yield Point(x, y);

  if (absdx > absdy) {
    var d = 2 * absdy - absdx;

    for (var i = 0; i < absdx; i++) {
      x = dx < 0 ? x - 1 : x + 1;
      if (d < 0) {
        d = d + 2 * absdy;
      } else {
        y = dy < 0 ? y - 1 : y + 1;
        d = d + (2 * absdy - 2 * absdx);
      }
      yield Point(x, y);
    }
  } else {
    // case when slope is greater than or equals to 1
    var d = 2 * absdx - absdy;

    for (var i = 0; i < absdy; i++) {
      y = dy < 0 ? y - 1 : y + 1;
      if (d < 0) {
        d = d + 2 * absdx;
      } else {
        x = dx < 0 ? x - 1 : x + 1;
        d = d + (2 * absdx) - (2 * absdy);
      }
      yield Point(x, y);
    }
  }

  /*var x1 = start.x;
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
  }*/
}
