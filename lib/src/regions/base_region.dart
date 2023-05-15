// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// A geographical region that forms a particular shape
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - [Widget] layer to be placed in a map: [toDrawable]
///  - list of [LatLng]s forming the outline: [toOutline]/[LineRegion.toOutlines]
///
/// Extended/implemented by:
///  - [RectangleRegion]
///  - [CircleRegion]
///  - [LineRegion]
sealed class BaseRegion {
  /// Create a geographical region that forms a particular shape
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - [Widget] layer to be placed in a map: [toDrawable]
  ///  - list of [LatLng]s forming the outline: [toOutline]/[LineRegion.toOutlines]
  ///
  /// Extended/implemented by:
  ///  - [RectangleRegion]
  ///  - [CircleRegion]
  ///  - [LineRegion]
  BaseRegion({required String? name})
      : name = (name?.isEmpty ?? false)
            ? throw ArgumentError.value(name, 'name', 'Must not be empty.')
            : name;

  /// The user friendly name for the region
  ///
  /// This is used within the recovery system, as well as to delete a particular
  /// downloaded region within a store.
  ///
  /// If `null`, this region will have no name. If specified, this must not be
  /// empty.
  ///
  /// _This property is currently redundant, but usage is planned in future
  /// versions._
  final String? name;

  /// Output a value of type [T] dependent on `this` and its type
  T when<T>({
    required T Function(RectangleRegion rectangle) rectangle,
    required T Function(CircleRegion circle) circle,
    required T Function(LineRegion line) line,
  }) =>
      switch (this) {
        RectangleRegion() => rectangle(this as RectangleRegion),
        CircleRegion() => circle(this as CircleRegion),
        LineRegion() => line(this as LineRegion),
      };

  /// Generate the [DownloadableRegion] ready for bulk downloading
  ///
  /// For more information see [DownloadableRegion]'s documentation.
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
  });

  /// Generate a graphical layer to be placed in a [FlutterMap]
  Widget toDrawable({
    Color? fillColor,
    Color borderColor = const Color(0x00000000),
    double borderStrokeWidth = 3,
    bool isDotted = false,
  });

  /// Generate the list of all the [LatLng]s forming the outline of this region
  ///
  /// Returns a `List<LatLng>` which can be used anywhere.
  List<LatLng> toOutline();

  @override
  @mustCallSuper
  @mustBeOverridden
  bool operator ==(Object other) =>
      identical(this, other) || (other is BaseRegion && other.name == name);

  @override
  @mustBeOverridden
  @mustCallSuper
  int get hashCode => name.hashCode;
}
