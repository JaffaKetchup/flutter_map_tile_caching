// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/foundation.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'base_region.dart';

/// Describes what shape, and therefore rules, a [DownloadableRegion] conforms to
enum RegionType {
  /// A region containing 2 points representing the top-left and bottom-right corners of a rectangle
  rectangle,

  /// A region containing all the points along it's outline (one every degree) representing a circle
  circle,

  /// A region with the border as the loci of a line at it's center representing multiple diagonal rectangles
  line,
}

/// A downloadable region to be passed to bulk download functions
///
/// Should avoid manual construction. Use a supported region shape and the `.toDownloadable()` extension on it.
///
/// Is returned from `.toDownloadable()`.
class DownloadableRegion {
  /// The shape that this region conforms to
  final RegionType type;

  /// The original [BaseRegion], used internally for recovery purposes
  final BaseRegion originalRegion;

  /// All the vertices on the outline of a polygon
  final List<LatLng> points;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// The options used to fetch tiles
  final TileLayer options;

  /// The number of download threads allowed to run simultaneously
  ///
  /// This will significantly increase speed, at the expense of faster battery drain. Note that some servers may forbid multithreading, in which case this should be set to 1, unless another limit is specified.
  ///
  /// Set to 1 to disable multithreading. Defaults to 10.
  final int parallelThreads;

  /// Whether to skip downloading tiles that already exist
  ///
  /// Defaults to `false`, so that existing tiles will be updated.
  final bool preventRedownload;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0, and z:19 to the bytes of the currently downloading tile. If they match, the tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satellite tiles (because of the variations from tile to tile), on maps where the tile 0/0/19 is not entirely sea, or on servers where zoom level 19 is not supported. If not supported, set this to `false` to avoid wasting unnecessary time and to avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be checked.
  ///
  /// Set to `false` to keep sea tiles, which is the default.
  final bool seaTileRemoval;

  /// Optionally skip past a number of tiles 'at the start' of a region
  ///
  /// Set to 0 to skip none, which is the default.
  final int start;

  /// Optionally skip a number of tiles 'at the end' of a region
  ///
  /// Set to `null` to skip none, which is the default.
  final int? end;

  /// The map projection to use to calculate tiles. Defaults to `Espg3857()`.
  final Crs crs;

  /// A function that takes any type of error as an argument to be called in the event a tile fetch fails
  final Function(Object?)? errorHandler;

  /// Avoid construction using this method. Use [BaseRegion.toDownloadable] to generate [DownloadableRegion]s from other regions.
  @internal
  DownloadableRegion.internal({
    required this.points,
    required this.minZoom,
    required this.maxZoom,
    required this.options,
    required this.type,
    required this.originalRegion,
    required this.parallelThreads,
    required this.preventRedownload,
    required this.seaTileRemoval,
    required this.start,
    required this.end,
    required this.crs,
    required this.errorHandler,
  }) {
    if (minZoom > maxZoom) {
      throw ArgumentError(
        '`minZoom` should be less than or equal to `maxZoom`',
      );
    }
    if (parallelThreads < 1) {
      throw ArgumentError(
        '`parallelThreads` should be more than or equal to 1. Set to 1 to disable multithreading',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadableRegion &&
        other.type == type &&
        other.originalRegion == originalRegion &&
        listEquals(other.points, points) &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        other.options == options &&
        other.parallelThreads == parallelThreads &&
        other.preventRedownload == preventRedownload &&
        other.seaTileRemoval == seaTileRemoval &&
        other.start == start &&
        other.end == end &&
        other.crs == crs &&
        other.errorHandler == errorHandler;
  }

  @override
  int get hashCode =>
      type.hashCode ^
      originalRegion.hashCode ^
      points.hashCode ^
      minZoom.hashCode ^
      maxZoom.hashCode ^
      options.hashCode ^
      parallelThreads.hashCode ^
      preventRedownload.hashCode ^
      seaTileRemoval.hashCode ^
      start.hashCode ^
      end.hashCode ^
      crs.hashCode ^
      errorHandler.hashCode;

  @override
  String toString() =>
      'DownloadableRegion(type: $type, originalRegion: $originalRegion, points: $points, minZoom: $minZoom, maxZoom: $maxZoom, options: $options, parallelThreads: $parallelThreads, preventRedownload: $preventRedownload, seaTileRemoval: $seaTileRemoval, start: $start, end: $end, crs: $crs, errorHandler: $errorHandler)';
}
