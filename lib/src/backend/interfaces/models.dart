// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../flutter_map_tile_caching.dart';
import '../../misc/obscure_query_params.dart';

/// Represents a store (which is never directly exposed to the user)
///
/// Note that the relationship between stores and tiles is many-to-many, and
/// backend implementations should fully support this.
abstract base class BackendStore {
  /// The human-readable name for this store
  ///
  /// Note that this may contain any character, and may also be empty.
  String get name;

  /// Uses [name] for equality comparisons only (unless the two objects are
  /// [identical])
  ///
  /// Overriding this in an implementation may cause FMTC logic to break, and is
  /// therefore not recommended.
  @override
  @nonVirtual
  bool operator ==(Object other) =>
      identical(this, other) || (other is BackendStore && name == other.name);

  @override
  @nonVirtual
  int get hashCode => name.hashCode;
}

/// Represents a tile (which is never directly exposed to the user)
///
/// Note that the relationship between stores and tiles is many-to-many, and
/// backend implementations should fully support this.
abstract base class BackendTile {
  /// The representative URL of the tile
  ///
  /// This is passed through [obscureQueryParams] before storage here, and so
  /// may not be the same as the network URL.
  String get url;

  /// The time at which the [bytes] of this tile were last changed
  ///
  /// This must be kept up to date, otherwise unexpected behaviour may occur
  /// when the [FMTCTileProviderSettings.maxStoreLength] is exceeded.
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
