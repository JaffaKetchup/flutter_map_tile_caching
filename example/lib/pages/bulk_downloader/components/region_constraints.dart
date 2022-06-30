import 'package:flutter/rendering.dart';

import '../bulk_downloader.dart';

class RegionConstraints {
  final BoxConstraints screenConstraints;
  final RegionMode mode;

  final int combinedPadding = 40;

  late final double height;
  late final double width;
  late final double top;
  late final double left;

  Offset get topLeft => Offset(left, top);
  Offset get bottomRight => Offset(left + width, top + height);
  Offset get edgeCenter => Offset(left + width / 2, top);
  Offset get middleCenter => Offset(left + width / 2, top + height / 2);

  double get shortestSide =>
      screenConstraints.maxHeight >= screenConstraints.maxWidth
          ? screenConstraints.maxWidth
          : screenConstraints.maxHeight;

  double get longestSide =>
      screenConstraints.maxHeight >= screenConstraints.maxWidth
          ? screenConstraints.maxHeight
          : screenConstraints.maxWidth;

  RegionConstraints({
    required this.screenConstraints,
    required this.mode,
  }) {
    final double pad = combinedPadding / 2;

    if (mode == RegionMode.rectangleVertical) {
      width = shortestSide - pad;
      height = longestSide - pad;
    } else if (mode == RegionMode.rectangleHorizontal) {
      width = shortestSide - pad;
      height = width / 1.5;
    } else {
      width = shortestSide - pad;
      height = width;
    }

    top = (screenConstraints.maxHeight - height) / 2;
    left = (screenConstraints.maxWidth - width) / 2;
  }

  @override
  String toString() {
    return 'RegionConstraints(screenConstraints: $screenConstraints, mode: $mode, height: $height, width: $width, top: $top, left: $left, screenConstraints.maxHeight: $screenConstraints.maxHeight, screenConstraints.maxWidth: $screenConstraints.maxWidth)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RegionConstraints &&
        other.screenConstraints == screenConstraints &&
        other.mode == mode &&
        other.height == height &&
        other.width == width &&
        other.top == top &&
        other.left == left &&
        other.screenConstraints.maxHeight == screenConstraints.maxHeight &&
        other.screenConstraints.maxWidth == screenConstraints.maxWidth;
  }

  @override
  int get hashCode {
    return screenConstraints.hashCode ^
        mode.hashCode ^
        height.hashCode ^
        width.hashCode ^
        top.hashCode ^
        left.hashCode ^
        screenConstraints.maxHeight.hashCode ^
        screenConstraints.maxWidth.hashCode;
  }
}
