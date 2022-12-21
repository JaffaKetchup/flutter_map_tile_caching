// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A region with the border as the locus of a line at it's center
class LineRegion implements BaseRegion {
  /// A line defined by a list of`LatLng`s
  final List<LatLng> line;

  /// The offset of the border in each direction in meters, like a radius
  final double radius;

  /// Creates a region with the border as the locus of a line at it's center
  LineRegion(this.line, this.radius);

  /// Creates a list of rectangles made of the locus of the specified line which can be used anywhere
  ///
  /// Use the optional `overlap` argument to set the rectangle joint(s) behaviours. -1 is reduced, 0 is normal (default), 1 is full (as downloaded).
  List<List<LatLng>> toOutlines([int overlap = 0]) {
    if (overlap < -1 || overlap > 1) {
      throw ArgumentError('`overlap` must be between -1 and 1 inclusive');
    }

    const Distance dist = Distance();
    final int rad = (radius * math.pi / 4).round();

    return line.map((pos) {
      if ((line.indexOf(pos) + 1) >= line.length) return [LatLng(0, 0)];

      final List<LatLng> section = [pos, line[line.indexOf(pos) + 1]];

      final double bearing = dist.bearing(section[0], section[1]);
      final double clockwiseRotation =
          (90 + bearing) > 360 ? 360 - (90 + bearing) : (90 + bearing);
      final double anticlockwiseRotation =
          (bearing - 90) < 0 ? 360 + (bearing - 90) : (bearing - 90);

      final LatLng offset1 =
          dist.offset(section[0], rad, clockwiseRotation); // Top-right
      final LatLng offset2 =
          dist.offset(section[1], rad, clockwiseRotation); // Bottom-right
      final LatLng offset3 =
          dist.offset(section[1], rad, anticlockwiseRotation); // Bottom-left
      final LatLng offset4 =
          dist.offset(section[0], rad, anticlockwiseRotation); // Top-left

      if (overlap == 0) return [offset1, offset2, offset3, offset4];

      final bool r = overlap == -1;
      final bool os = line.indexOf(pos) == 0;
      final bool oe = line.indexOf(pos) == line.length - 2;

      return [
        os ? offset1 : dist.offset(offset1, r ? rad : -rad, bearing),
        oe ? offset2 : dist.offset(offset2, r ? -rad : rad, bearing),
        oe ? offset3 : dist.offset(offset3, r ? -rad : rad, bearing),
        os ? offset4 : dist.offset(offset4, r ? rad : -rad, bearing),
      ];
    }).toList()
      ..removeLast();
  }

  @override
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayer options, {
    int parallelThreads = 10,
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    int start = 0,
    int? end,
    Crs crs = const Epsg3857(),
    void Function(Object?)? errorHandler,
  }) =>
      DownloadableRegion._(
        points: toOutlines(1).expand((x) => x).toList(),
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        type: RegionType.line,
        originalRegion: this,
        parallelThreads: parallelThreads,
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        start: start,
        end: end,
        crs: crs,
        errorHandler: errorHandler,
      );

  /// Create a drawable area for a [FlutterMap] out of this region
  ///
  /// [prettyPaint] controls what type of shape will be output. If `false`,
  /// multiple overlapping rectangular [Polygon]s will be output, representing
  /// the area that will actually be downloaded. If `true` (default), a
  /// [Polyline] will be output, which handles all the nice rounding and some
  /// other stuff that makes it more suitable to present to the user.
  ///
  /// Some parameters will only have an effect depending whether a [Polygon] or
  /// [Polyline] is being output.
  ///
  /// Returns a layer to be added to the `layer` property of a [FlutterMap].
  @override
  Widget toDrawable({
    Color? fillColor,
    Color? borderColor,
    double borderStrokeWidth = 3,
    bool isDotted = false,
    bool prettyPaint = true,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
    List<Color>? gradientColors,
    List<double>? colorsStop,
  }) =>
      prettyPaint
          ? PolylineLayer(
              polylines: [
                Polyline(
                  points: line,
                  strokeWidth: radius,
                  useStrokeWidthInMeter: true,
                  color: fillColor ?? const Color(0x00000000),
                  borderColor: borderColor ?? const Color(0x00000000),
                  borderStrokeWidth: borderStrokeWidth,
                  isDotted: isDotted,
                  gradientColors: gradientColors,
                  colorsStop: colorsStop,
                  strokeCap: strokeCap,
                  strokeJoin: strokeJoin,
                ),
              ],
            )
          : PolygonLayer(
              polygons: toOutlines(1)
                  .map(
                    (rect) => Polygon(
                      points: rect,
                      isFilled: fillColor != null,
                      color: fillColor ?? Colors.transparent,
                      borderColor: borderColor ?? const Color(0x00000000),
                      borderStrokeWidth: borderStrokeWidth,
                      isDotted: isDotted,
                      strokeCap: strokeCap,
                      strokeJoin: strokeJoin,
                    ),
                  )
                  .toList(),
            );

  /// This method is unavailable for this region type: use [toOutlines] instead
  @alwaysThrows
  @override
  List<LatLng> toList() {
    throw UnsupportedError(
      '`toList` is invalid for this region type: use `toOutlines()` instead',
    );
  }
}
