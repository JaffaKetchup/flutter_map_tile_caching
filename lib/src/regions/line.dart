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
  LineRegion(this.line, this.radius, {super.name}) : super();

  /// The center line defined by a list of coordinates
  final List<LatLng> line;

  /// The offset of the outline from the [line] in all directions (in meters)
  final double radius;

  /// Generate the list of rectangle segments formed from the locus of this line
  ///
  /// Use the optional [overlap] argument to set the behaviour of the joints
  /// between segments:
  ///
  /// * -1: joined by closest corners (largest gap)
  /// * 0 (default): joined by centers
  /// * 1 (as downloaded): joined by further corners (largest overlap)
  List<List<LatLng>> toOutlines([int overlap = 0]) {
    if (overlap < -1 || overlap > 1) {
      throw ArgumentError('`overlap` must be between -1 and 1 inclusive');
    }

    if (line.isEmpty) return [];

    const dist = Distance();
    final rad = radius * math.pi / 4;

    return line.map((pos) {
      if ((line.indexOf(pos) + 1) >= line.length) return [const LatLng(0, 0)];

      final section = [pos, line[line.indexOf(pos) + 1]];

      final bearing = dist.bearing(section[0], section[1]);
      final clockwiseRotation =
          (90 + bearing) > 360 ? 360 - (90 + bearing) : (90 + bearing);
      final anticlockwiseRotation =
          (bearing - 90) < 0 ? 360 + (bearing - 90) : (bearing - 90);

      final topRight = dist.offset(section[0], rad, clockwiseRotation);
      final bottomRight = dist.offset(section[1], rad, clockwiseRotation);
      final bottomLeft = dist.offset(section[1], rad, anticlockwiseRotation);
      final topLeft = dist.offset(section[0], rad, anticlockwiseRotation);

      if (overlap == 0) return [topRight, bottomRight, bottomLeft, topLeft];

      final r = overlap == -1;
      final os = line.indexOf(pos) == 0;
      final oe = line.indexOf(pos) == line.length - 2;

      return [
        os ? topRight : dist.offset(topRight, r ? rad : -rad, bearing),
        oe ? bottomRight : dist.offset(bottomRight, r ? -rad : rad, bearing),
        oe ? bottomLeft : dist.offset(bottomLeft, r ? -rad : rad, bearing),
        os ? topLeft : dist.offset(topLeft, r ? rad : -rad, bearing),
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
  /// > Generate the list of rectangle segments formed from the locus of this
  /// > line
  /// >
  /// > Use the optional [overlap] argument to set the behaviour of the joints
  /// between segments:
  /// >
  /// > * -1: joined by closest corners (largest gap),
  /// > * 0 (default): joined by centers
  /// > * 1 (as downloaded): joined by further corners (most overlap)
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
