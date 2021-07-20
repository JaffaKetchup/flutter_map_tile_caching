import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:meta/meta.dart';

/// Wrapper widget for `FlutterMap()` to extend the map beyond the normal viewport to preload a certain number of tiles in each direction to avoid grey tiles
///
/// CAUTION: Experimental. May not work as intended. Avoid all usage.
@experimental
class PreloadSurroundings extends StatelessWidget {
  /// The `FlutterMap()`
  final FlutterMap map;

  /// The number of tiles to preload in each direction
  final int tilesAmount;

  /// The 'physical pixels' width/height of a single tile
  final CustomPoint<num> tileSize;

  /// The base width of the map. Defaults to full screen width.
  ///
  /// If you do not know the width, use an `Expanded()` widget inside a `Row()`, and leave this as default. However, this is not recommended.
  final double? width;

  /// The base height of the map. Defaults to full screen height.
  ///
  /// If you do not know the height, use an `Expanded()` widget inside a `Column()`, and leave this as default. However, this is not recommended.
  final double? height;

  /// Create a wrapper widget for `FlutterMap()` to extend the map beyond the normal viewport to preload a certain number of tiles in each direction to avoid grey tiles
  const PreloadSurroundings({
    Key? key,
    required this.map,
    this.tilesAmount = 2,
    this.tileSize = const CustomPoint(256, 256),
    this.width,
    this.height,
  }) : super(
          key: key,
        );

  /*@override
  Widget build(BuildContext context) {
    final num _formula =
        ((tileSize.x * tilesAmount) / MediaQuery.of(context).devicePixelRatio);

    return Stack(
      children: [
        Positioned(
          top: -(((height ?? MediaQuery.of(context).size.height) + _formula) /
              2),
          left:
              -(((width ?? MediaQuery.of(context).size.width) + _formula) / 2),
          child: SizedBox(
            width: (width ?? MediaQuery.of(context).size.width) * 2 + _formula,
            height:
                (height ?? MediaQuery.of(context).size.height) * 2 + _formula,
            child: map,
          ),
        ),
      ],
    );
  }*/

  @override
  Widget build(BuildContext context) {
    final double _formula = tilesAmount *
        (tileSize.x.toDouble() / MediaQuery.of(context).devicePixelRatio);
    final double _wth = width ?? MediaQuery.of(context).size.width;
    final double _hgt = height ?? MediaQuery.of(context).size.height;
    print(_formula);
    return SizedBox(
      width: _wth,
      height: _hgt,
      child: Stack(
        children: [
          Positioned(
            child: map,
            left: -_formula,
            top: -_formula,
            right: _formula,
            bottom: _formula,
          ),
        ],
        clipBehavior: Clip.none,
      ),
    );
  }
}
