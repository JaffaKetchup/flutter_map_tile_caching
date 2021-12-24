// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
@Deprecated(
    'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
class ShapeChooserResult {
  /// The drawable polygon created from the `ShapeChooser`
  ///
  /// Recommended to use `ShapeChooserResult.toDrawable()` instead as it makes it much easier to add to the map (literally just add that function to the map's `layers` parameter) and it handles null.
  final PolygonLayerOptions? selectedAreaPolygon;

  /// The region created from the `ShapeChooser` as it's appropriate region type
  final BaseRegion? selectedRegion;

  /// Flag to signify whether `selectedAreaPolygon` and `selectedRegion` are available yet
  final bool ready;

  /// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
  @Deprecated(
      'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
  @internal
  ShapeChooserResult([
    this.ready = false,
    this.selectedAreaPolygon,
    this.selectedRegion,
  ]);
}

/// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
@Deprecated(
    'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
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

  /// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
  @Deprecated(
      'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
  ShapeChooser(
    this.choosingShape, {
    required this.fillColor,
    required this.borderColor,
    this.borderStrokeWidth = 3.0,
    this.isDotted = false,
  });

  /// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
  @Deprecated(
      'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
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
            Distance().distance(_selectedPoints[0], _selectedPoints[1]),
          ).toDrawable(fillColor, borderColor,
              borderStrokeWidth: borderStrokeWidth, isDotted: isDotted),
          CircleRegion(
            _selectedPoints[0],
            Distance().distance(_selectedPoints[0], _selectedPoints[1]),
          ),
        );
      } else if (choosingShape == RegionType.line) {
        throw UnimplementedError();
      }
    }

    reset();
    return onTapReciever(point);
  }

  /// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
  @Deprecated(
      'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
  void reset() {
    _step = 0;
    _selectedPoints.clear();
  }
}

/// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
@Deprecated(
    'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
extension ShapeChooserResultExts on ShapeChooserResult? {
  /// Deprecated due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.
  @Deprecated(
      'Due to overcomplication leading to need for code reduction. This same functionality can be easily constructed on a case-to-case basis using just one or two variables. See the example project for how to do this.')
  PolygonLayerOptions toDrawable() {
    return this?.selectedAreaPolygon ?? PolygonLayerOptions();
  }
}
