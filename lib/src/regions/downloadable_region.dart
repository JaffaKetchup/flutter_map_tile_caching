// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// A downloadable region to be passed to bulk download functions
///
/// Construct via [BaseRegion.toDownloadable].
class DownloadableRegion<R extends BaseRegion> {
  /// A copy of the [BaseRegion] used to form this object
  ///
  /// To make decisions based on the type of this region, prefer [when] over
  /// switching on [R] manually.
  final R originalRegion;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// The options used to fetch tiles
  final TileLayer options;

  /// The number of download threads allowed to run simultaneously
  ///
  /// This will significantly increase speed, at the expense of faster battery
  /// drain. Note that some servers may forbid multithreading, in which case this
  /// should be set to 1, unless another limit is specified.
  ///
  /// Set to 1 to disable multithreading. Defaults to 10.
  final int parallelThreads;

  /// Whether to skip downloading tiles that already exist
  ///
  /// Defaults to `false`, so that existing tiles will be updated.
  final bool preventRedownload;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0,
  /// and z:19 to the bytes of the currently downloading tile. If they match, the
  /// tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satellite tiles (because
  /// of the variations from tile to tile), on maps where the tile 0/0/19 is not
  /// entirely sea, or on servers where zoom level 19 is not supported. If not
  /// supported, set this to `false` to avoid wasting unnecessary time and to
  /// avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature:
  /// tiles still have to be fully downloaded before they can be checked.
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

  /// The map projection to use to calculate tiles. Defaults to [Epsg3857].
  final Crs crs;

  /// A function that takes any type of error as an argument to be called in the
  /// event a tile fetch fails
  final void Function(Object?)? errorHandler;

  DownloadableRegion._(
    this.originalRegion, {
    required this.minZoom,
    required this.maxZoom,
    required this.options,
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

  /// Output a value of type [T] dependent on [originalRegion] and its type [R]
  ///
  /// Shortcut for [BaseRegion.when].
  T when<T>({
    required T Function(RectangleRegion rectangle) rectangle,
    required T Function(CircleRegion circle) circle,
    required T Function(LineRegion line) line,
  }) =>
      originalRegion.when(rectangle: rectangle, circle: circle, line: line);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadableRegion &&
          other.originalRegion == originalRegion &&
          other.minZoom == minZoom &&
          other.maxZoom == maxZoom &&
          other.options == options &&
          other.parallelThreads == parallelThreads &&
          other.preventRedownload == preventRedownload &&
          other.seaTileRemoval == seaTileRemoval &&
          other.start == start &&
          other.end == end &&
          other.crs == crs &&
          other.errorHandler == errorHandler);

  @override
  int get hashCode => Object.hashAllUnordered([
        originalRegion.hashCode,
        minZoom.hashCode,
        maxZoom.hashCode,
        options.hashCode,
        parallelThreads.hashCode,
        preventRedownload.hashCode,
        seaTileRemoval.hashCode,
        start.hashCode,
        end.hashCode,
        crs.hashCode,
        errorHandler.hashCode,
      ]);

  @override
  String toString() =>
      'DownloadableRegion(originalRegion: $originalRegion, minZoom: $minZoom, maxZoom: $maxZoom, options: $options, parallelThreads: $parallelThreads, preventRedownload: $preventRedownload, seaTileRemoval: $seaTileRemoval, start: $start, end: $end, crs: $crs, errorHandler: $errorHandler)';
}
