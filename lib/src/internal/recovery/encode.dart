// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:flutter_map/plugin_api.dart';
import 'package:ini/ini.dart';
import 'package:latlong2/latlong.dart';

import '../../regions/circle.dart';
import '../../regions/downloadable_region.dart';
import '../../regions/line.dart';
import '../../regions/rectangle.dart';
import '../../root/directory.dart';
import '../exts.dart';

Future<void> encode({
  required int id,
  required String storeName,
  required DownloadableRegion region,
  required RootDirectory rootDirectory,
}) async {
  final File file = rootDirectory.access.recovery >>> '$id.recovery.ini';
  await file.create(recursive: true);

  final Config cfg = Config.fromStrings(await file.readAsLines())
    ..addSection('info')
    ..set('info', 'id', id.toString())
    ..set('info', 'storeName', storeName)
    ..set('info', 'time', DateTime.now().millisecondsSinceEpoch.toString())
    ..set('info', 'regionType', region.type.name)
    ..addSection('zoom')
    ..set('zoom', 'minZoom', region.minZoom.toString())
    ..set('zoom', 'maxZoom', region.maxZoom.toString())
    ..addSection('skip')
    ..set('skip', 'start', region.start.toString())
    ..set('skip', 'end', region.end.toString())
    ..addSection('opts')
    ..set('opts', 'parallelThreads', region.parallelThreads.toString())
    ..set('opts', 'preventRedownload', region.preventRedownload.toString())
    ..set('opts', 'seaTileRemoval', region.seaTileRemoval.toString())
    ..addSection('area');

  if (region.type == RegionType.rectangle) {
    final LatLngBounds bounds =
        (region.originalRegion as RectangleRegion).bounds;

    cfg
      ..set('area', 'nwLat', bounds.northWest.latitude.toString())
      ..set('area', 'nwLng', bounds.northWest.longitude.toString())
      ..set('area', 'seLat', bounds.southEast.latitude.toString())
      ..set('area', 'seLng', bounds.southEast.longitude.toString());
  } else if (region.type == RegionType.circle) {
    final reg = region.originalRegion as CircleRegion;

    cfg
      ..set('area', 'cLat', reg.center.latitude.toString())
      ..set('area', 'cLng', reg.center.longitude.toString())
      ..set('area', 'radius', reg.radius.toString());
  } else if (region.type == RegionType.line) {
    final reg = region.originalRegion as LineRegion;

    int i = 0;
    for (final LatLng point in reg.line) {
      cfg
        ..set('area', 'length', i.toString())
        ..set('area', '$i Lat', point.latitude.toString())
        ..set('area', '$i Lng', point.longitude.toString());

      i++;
    }

    cfg.set('area', 'radius', reg.radius.toString());
  }

  await file.writeAsString(cfg.toString(), flush: true);
}
