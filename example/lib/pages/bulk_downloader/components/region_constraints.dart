import 'package:flutter/rendering.dart';

class RegionConstraints {
  final BoxConstraints screenConstraints;
  final double combinedPadding;
  final bool isNonSquare;

  late final double height;
  late final double width;
  late final double top;
  late final double left;

  Offset get topLeft => Offset(left, top);
  Offset get bottomRight => Offset(left + width, top + height);
  Offset get edgeCenter => Offset(left + width / 2, top);
  Offset get middleCenter => Offset(left + width / 2, top + height / 2);

  RegionConstraints({
    required this.screenConstraints,
    this.combinedPadding = 40,
    this.isNonSquare = false,
  }) {
    final double pad = combinedPadding / 2;

    width = shortestSide(screenConstraints) - pad;
    height = isNonSquare ? longestSide(screenConstraints) - pad : width;

    top = (screenConstraints.maxHeight - height) / 2;
    left = (screenConstraints.maxWidth - width) / 2;
  }

  static double shortestSide(BoxConstraints sc) =>
      sc.maxHeight >= sc.maxWidth ? sc.maxWidth : sc.maxHeight;

  static double longestSide(BoxConstraints sc) =>
      sc.maxHeight >= sc.maxWidth ? sc.maxHeight : sc.maxWidth;
}
