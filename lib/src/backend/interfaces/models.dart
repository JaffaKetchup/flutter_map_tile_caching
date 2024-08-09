// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../flutter_map_tile_caching.dart';

/// Represents a tile (which is never directly exposed to the user)
///
/// Note that the relationship between stores and tiles is many-to-many, and
/// backend implementations should fully support this.
abstract base class BackendTile {
  /// The storage-suitable UID of the tile
  ///
  /// This is the result of [FMTCTileProvider.urlTransformer].
  String get url;

  /// The time at which the [bytes] of this tile were last changed
  ///
  /// This must be kept up to date, otherwise unexpected behaviour may occur
  /// when the store's `maxLength` is exceeded.
  DateTime get lastModified;

  /// The raw bytes of the image of this tile
  Uint8List get bytes;

  /// Uses [url] for equality comparisons only (unless the two objects are
  /// [identical])
  ///
  /// Overriding this in an implementation may cause FMTC logic to break, and is
  /// therefore not recommended.
  @override
  @nonVirtual
  bool operator ==(Object other) =>
      identical(this, other) || (other is BackendTile && url == other.url);

  @override
  @nonVirtual
  int get hashCode => url.hashCode;
}
