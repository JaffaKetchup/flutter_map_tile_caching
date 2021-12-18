import 'package:flutter/rendering.dart';

abstract class Constraints {
  static double _heightOrWidth(BoxConstraints screenConstraints,
          [bool reversed = false]) =>
      (!reversed
              ? screenConstraints.maxHeight >= screenConstraints.maxWidth
              : screenConstraints.maxWidth >= screenConstraints.maxHeight)
          ? screenConstraints.maxHeight
          : screenConstraints.maxWidth;

  double get top => 0;
  double get left => 0;
  double get height => 0;
  double get width => 0;

  Offset get topLeft => Offset(left, top);
  Offset get bottomRight => Offset(left + width, top + height);

  Offset get edgeCenter => Offset(left + width / 2, top);
  Offset get middleCenter => Offset(left + width / 2, top + height / 2);
}

class SquareConstraints extends Constraints {
  final BoxConstraints screenConstraints;
  final double combinedPadding;

  @override
  late final double height;
  @override
  late final double width;

  @override
  late final double top;
  @override
  late final double left;

  SquareConstraints(
    this.screenConstraints,
    this.combinedPadding,
  ) {
    final double dimension =
        Constraints._heightOrWidth(screenConstraints, true) -
            (combinedPadding / 2);

    height = dimension;
    width = dimension;
    top = (screenConstraints.maxHeight - dimension) / 2;
    left = (screenConstraints.maxWidth - dimension) / 2;
  }
}

class RectangleConstraints extends Constraints {
  final BoxConstraints screenConstraints;
  final double combinedPadding;
  @override
  late final double height;
  @override
  late final double width;

  @override
  late final double top;
  @override
  late final double left;

  RectangleConstraints(
    this.screenConstraints,
    this.combinedPadding,
  ) {
    height =
        Constraints._heightOrWidth(screenConstraints) - (combinedPadding / 2);
    width = Constraints._heightOrWidth(screenConstraints, true) -
        (combinedPadding / 2);

    top = (screenConstraints.maxHeight - height) / 2;
    left = (screenConstraints.maxWidth - width) / 2;
  }
}
