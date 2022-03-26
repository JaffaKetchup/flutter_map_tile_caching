import 'dart:io';

import 'package:flutter_map/plugin_api.dart';
import 'package:ini/ini.dart';
import 'package:latlong2/latlong.dart';

import '../../regions/circle.dart';
import '../../regions/downloadable_region.dart';
import '../../regions/line.dart';
import '../../regions/rectangle.dart';

Future<void> start(
  File file,
  DownloadableRegion region,
  String identification,
) async {
  if (await file.exists()) {
    throw StateError(
      'A download recovery file already exists. Only one download recovery per store is supported: use `cancelDownload()` if there is an ongoing download, or `recoverDownload()` to recover and delete the file if there is no download.',
    );
  }
  await file.create(recursive: true);

  final Config cfg = Config.fromStrings(await file.readAsLines());

  cfg.addSection('info');
  cfg.set('info', 'identification', identification);
  cfg.set('info', 'regionType', region.type.name);

  cfg.addSection('zoom');
  cfg.set('zoom', 'minZoom', region.minZoom.toString());
  cfg.set('zoom', 'maxZoom', region.maxZoom.toString());

  cfg.addSection('skip');
  cfg.set('skip', 'start', region.start.toString());
  cfg.set('skip', 'end', region.end.toString());

  cfg.addSection('opts');
  cfg.set('opts', 'parallelThreads', region.parallelThreads.toString());
  cfg.set('opts', 'preventRedownload', region.preventRedownload.toString());
  cfg.set('opts', 'seaTileRemoval', region.seaTileRemoval.toString());

  cfg.addSection('area');
  if (region.type == RegionType.rectangle) {
    final LatLngBounds bounds =
        (region.originalRegion as RectangleRegion).bounds;

    cfg.set('area', 'nwLat', bounds.northWest.latitude.toString());
    cfg.set('area', 'nwLng', bounds.northWest.longitude.toString());
    cfg.set('area', 'seLat', bounds.southEast.latitude.toString());
    cfg.set('area', 'seLng', bounds.southEast.longitude.toString());
  } else if (region.type == RegionType.circle) {
    final reg = region.originalRegion as CircleRegion;

    cfg.set('area', 'cLat', reg.center.latitude.toString());
    cfg.set('area', 'cLng', reg.center.longitude.toString());
    cfg.set('area', 'radius', reg.radius.toString());
  } else if (region.type == RegionType.line) {
    final reg = region.originalRegion as LineRegion;

    int i = 0;
    for (LatLng point in reg.line) {
      cfg.set('area', 'length', i.toString());
      cfg.set('area', i.toString() + 'Lat', point.latitude.toString());
      cfg.set('area', i.toString() + 'Lng', point.longitude.toString());

      i++;
    }

    cfg.set('area', 'radius', reg.radius.toString());
  }

  await file.writeAsString(cfg.toString(), flush: true);
}
