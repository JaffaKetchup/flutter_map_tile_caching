// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'base_region.dart';
import 'circle.dart';
import 'downloadable_region.dart';
import 'line.dart';
import 'rectangle.dart';

/// A mixture between [BaseRegion] and [DownloadableRegion] containing all the salvaged data from a recovered download
///
/// How does recovery work? At the start of a download, a file is created including information about the download. At the end of a download or when a download is correctly cancelled, this file is deleted. However, if there is no ongoing download (controlled by an internal variable) and the recovery file exists, the download has obviously been stopped incorrectly, meaning it can be recovered using the information within the recovery file.
///
/// The availability of [bounds], [line], [center] & [radius] depend on the [type] of the recovered region.
///
/// Should avoid manual construction. Use [toDownloadable] to restore a valid [DownloadableRegion].
class RecoveredRegion {
  /// The file that this region was contained in
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final File file;

  /// A unique ID created for every bulk download operation
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final int id;

  /// The store name originally associated with this download.
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final String storeName;

  /// The time at which this recovery was started
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final DateTime time;

  /// The shape that this region conforms to
  final RegionType type;

  /// The bounds for a rectangular region
  final LatLngBounds? bounds;

  /// The line making a line-based region
  final List<LatLng>? line;

  /// The center of a circular region
  final LatLng? center;

  /// The radius of a circular region
  final double? radius;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// Optionally skip past a number of tiles 'at the start' of a region
  final int start;

  /// Optionally skip a number of tiles 'at the end' of a region
  final int? end;

  /// The number of download threads allowed to run simultaneously
  ///
  /// This will significantly increase speed, at the expense of faster battery drain. Note that some servers may forbid multithreading, in which case this should be set to 1, unless another limit is specified.
  final int parallelThreads;

  /// Whether to skip downloading tiles that already exist
  final bool preventRedownload;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0, and z:19 to the bytes of the currently downloading tile. If they match, the tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satellite tiles (because of the variations from tile to tile), on maps where the tile 0/0/19 is not entirely sea, or on servers where zoom level 19 is not supported. If not supported, set this to `false` to avoid wasting unnecessary time and to avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be checked.
  final bool seaTileRemoval;

  /// Avoid construction using this method
  @internal
  RecoveredRegion.internal({
    required this.file,
    required this.id,
    required this.storeName,
    required this.time,
    required this.type,
    required this.bounds,
    required this.center,
    required this.line,
    required this.radius,
    required this.minZoom,
    required this.maxZoom,
    required this.start,
    required this.end,
    required this.parallelThreads,
    required this.preventRedownload,
    required this.seaTileRemoval,
  });

  /// Convert this region into a downloadable region
  DownloadableRegion toDownloadable(
    TileLayer options, {
    Crs crs = const Epsg3857(),
    Function(Object?)? errorHandler,
  }) {
    final BaseRegion region = type == RegionType.rectangle
        ? RectangleRegion(bounds!)
        : type == RegionType.circle
            ? CircleRegion(center!, radius!)
            : LineRegion(line!, radius!);

    return DownloadableRegion.internal(
      points: region.toList(),
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: options,
      type: type,
      originalRegion: region,
      parallelThreads: parallelThreads,
      preventRedownload: preventRedownload,
      seaTileRemoval: seaTileRemoval,
      start: start,
      end: end,
      crs: crs,
      errorHandler: errorHandler,
    );
  }
}
