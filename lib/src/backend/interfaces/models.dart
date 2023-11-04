import 'dart:typed_data';

abstract base class BackendStore {
  abstract String name;

  /// Uses [name] for equality comparisons only (unless the two objects are
  /// [identical])
  @override
  bool operator ==(Object? other) =>
      identical(this, other) || (other is BackendStore && name == other.name);

  @override
  int get hashCode => name.hashCode;
}

abstract base class BackendTile {
  abstract String url;
  abstract DateTime lastModified;
  abstract Uint8List bytes;

  /// Uses [url] for equality comparisons only (unless the two objects are
  /// [identical])
  @override
  bool operator ==(Object? other) =>
      identical(this, other) || (other is BackendTile && url == other.url);

  @override
  int get hashCode => url.hashCode;
}
