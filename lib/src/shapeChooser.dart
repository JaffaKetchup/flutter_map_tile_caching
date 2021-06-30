import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'regions/downloadableRegion.dart';

/// The value returned from `ShapeChooser`
class ShapeChooserResult {
  /// The drawable polygon created from the `ShapeChooser`
  ///
  /// Recommended to use `ShapeChooserResult.toDrawable()` instead as it makes it much easier to add to the map (literally just add that function to the map's `layers` parameter) and it handles null.
  final PolygonLayerOptions? selectedAreaPolygon;

  /// The region created from the `ShapeChooser` as it's appropriate region type
  final BaseRegion? selectedRegion;

  /// Flag to signify whether `selectedAreaPolygon` and `selectedRegion` are available yet
  final bool ready;

  /// The value returned from `ShapeChooser`
  ///
  /// Should avoid manual construction.
  @internal
  ShapeChooserResult([
    this.ready = false,
    this.selectedAreaPolygon,
    this.selectedRegion,
  ]);
}

/// A class to allow the user to easily select a region for downloading
class ShapeChooser {
  /// Dictates what shape rules the area will conform to
  final RegionType choosingShape;

  /// The fill color for the drawable polygon
  ///
  /// Don't use opaque colors, as this will hide the map beneath
  final Color fillColor;

  /// The border color for the drawable polygon
  final Color borderColor;

  /// The width of the border of the drawable polygon
  final double borderStrokeWidth;

  /// Whether the border of the drawable polygon is dotted instead of solid
  final bool isDotted;

  int _step = 0;
  final List<LatLng> _selectedPoints = [];

  /// A class to allow the user to easily select a region for downloading
  ShapeChooser(
    this.choosingShape, {
    required this.fillColor,
    required this.borderColor,
    this.borderStrokeWidth = 3.0,
    this.isDotted = false,
  });

  /// Attach to the `onTap` callback of a map to automatically generate the region
  ///
  /// Returns a `ShapeChooserResult`.
  ShapeChooserResult onTapReciever(LatLng point) {
    if (_step == 0) {
      _selectedPoints.add(point);
      _step++;
      if (choosingShape == RegionType.rectangle) {
        return ShapeChooserResult();
      } else if (choosingShape == RegionType.circle) {
        return ShapeChooserResult();
      } else if (choosingShape == RegionType.line) {
        throw UnimplementedError();
      } else if (choosingShape == RegionType.customPolygon) {
        throw UnimplementedError();
      }
    }
    if (_step == 1) {
      _selectedPoints.add(point);
      _step++;
      if (choosingShape == RegionType.rectangle) {
        return ShapeChooserResult(
          true,
          PolygonLayerOptions(
            polygons: [
              Polygon(
                color: fillColor,
                borderColor: borderColor,
                borderStrokeWidth: borderStrokeWidth,
                isDotted: isDotted,
                points: [
                  _selectedPoints[0],
                  LatLng(_selectedPoints[1].latitude,
                      _selectedPoints[0].longitude),
                  _selectedPoints[1],
                  LatLng(_selectedPoints[0].latitude,
                      _selectedPoints[1].longitude),
                ],
              )
            ],
          ),
          RectangleRegion(LatLngBounds(_selectedPoints[0], _selectedPoints[1])),
        );
      } else if (choosingShape == RegionType.circle) {
        return ShapeChooserResult(
          true,
          CircleRegion(
            _selectedPoints[0],
            _selectedPoints[0].distanceTo(_selectedPoints[1]),
          ).toDrawable(fillColor, borderColor,
              borderStrokeWidth: borderStrokeWidth, isDotted: isDotted),
          CircleRegion(
            _selectedPoints[0],
            _selectedPoints[0].distanceTo(_selectedPoints[1]),
          ),
        );
      } else if (choosingShape == RegionType.line) {
        throw UnimplementedError();
      } else if (choosingShape == RegionType.customPolygon) {
        throw UnimplementedError();
      }
    }

    reset();
    return onTapReciever(point);
  }

  /// Reset the step counter of this `ShapeChooser()` (allows selection of new shape)
  void reset() {
    _step = 0;
    _selectedPoints.clear();
  }
}

extension shapeChooserResultExts on ShapeChooserResult? {
  /// Convert the `ShapeChooserResult`, which is normally nullable, to a `PolygonLayerOptions` (never null) to be drawn immediately
  PolygonLayerOptions toDrawable() {
    return this?.selectedAreaPolygon ?? PolygonLayerOptions();
  }
}
