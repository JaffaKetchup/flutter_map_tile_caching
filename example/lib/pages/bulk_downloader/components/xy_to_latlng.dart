import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

Future<LatLng> xyToLatLng({
  required MapController controller,
  required Offset offset,
  required double height,
  required double width,
}) async {
  /*return await compute(
    (Map<String, dynamic> input) {
      final CustomPoint<num> focalStartPt = const Epsg3857().latLngToPoint(
          LatLng(input['center'][0], input['center'][1]), input['zoom']);

      final CustomPoint<num> point =
          (CustomPoint(input['offset'].dx, input['offset'].dy) -
                  (CustomPoint<double>(
                          input['width'], input['height'] - kToolbarHeight) /
                      2.0))
              .rotate(input['rotation'] * pi / 180);

      return const Epsg3857()
          .pointToLatLng(focalStartPt + point, input['zoom'])!;
    },
    {
      'height': height,
      'width': width,
      'center': [controller.center.latitude, controller.center.longitude],
      'zoom': controller.zoom,
      'rotation': controller.rotation,
      'offset': offset,
    },
  );*/

  final Map<String, dynamic> input = {
    'height': height,
    'width': width,
    'center': [controller.center.latitude, controller.center.longitude],
    'zoom': controller.zoom,
    'rotation': controller.rotation,
    'offset': offset,
  };

  final CustomPoint<num> focalStartPt = const Epsg3857().latLngToPoint(
      LatLng(input['center'][0], input['center'][1]), input['zoom']);

  final CustomPoint<num> point =
      (CustomPoint(input['offset'].dx, input['offset'].dy) -
              (CustomPoint<double>(
                      input['width'], input['height'] - kToolbarHeight) /
                  2.0))
          .rotate(input['rotation'] * pi / 180);

  return const Epsg3857().pointToLatLng(focalStartPt + point, input['zoom'])!;
}
