// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// A geographically line/locus region based off a list of coords and a [radius]
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - [Widget] layer to be placed in a map: [toDrawable]
///  - list of [LatLng]s forming the outline: [LineRegion.toOutlines]
class LineRegion extends BaseRegion {
  /// A geographically line/locus region based off a list of coords and a [radius]
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - [Widget] layer to be placed in a map: [toDrawable]
  ///  - list of [LatLng]s forming the outline: [LineRegion.toOutlines]
  LineRegion(
    this.line,
    this.radius, {
    super.name,
  });

  /// The center line defined by a list of coordinates
  final List<LatLng> line;

  /// The offset of the outline from the [line] in all directions (in meters)
  final double radius;

  /// Generate the list of rectangle segments formed from the locus of this line
  ///
  /// Use the optional `overlap` argument to set the behaviour of the joints
  /// between segments:
  ///
  /// * -1: joined by closest corners (largest gap)
  /// * 0 (default): joined by centers (equal gap and overlap)
  /// * 1 (as downloaded): joined by further corners (largest overlap)
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
        this,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        parallelThreads: parallelThreads,
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        start: start,
        end: end,
        crs: crs,
        errorHandler: errorHandler,
      );

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

  /// Flattens the result of [toOutlines] - its documentation is quoted below
  ///
  /// Prefer [toOutlines]. This method is likely to give a different result than
  /// expected if used externally.
  ///
  /// > Generate the list of rectangle segments formed from the locus of this
  /// > line
  /// >
  /// > Use the optional `overlap` argument to set the behaviour of the joints
  /// between segments:
  /// >
  /// > * -1: joined by closest corners (largest gap),
  /// > * 0: joined by centers (equal gap and overlap)
  /// > * 1 (default, as downloaded): joined by further corners (most overlap)
  @override
  List<LatLng> toOutline([int overlap = 1]) =>
      toOutlines(overlap).expand((x) => x).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineRegion &&
          other.line == line &&
          listEquals(other.line, line) &&
          other.radius == radius &&
          super == other);

  @override
  int get hashCode => Object.hashAllUnordered([line, radius, super.hashCode]);
}
