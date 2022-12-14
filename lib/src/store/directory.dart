// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Represents a store of tiles
///
/// The tile store itself is a database referred to in the registry
/// (see [FMTCRegistry]). The database contains tiles, as well as metadata.
///
/// The name originates from previous versions of this library, where it
/// represented a real directory instead of a database.
///
/// Reach through [FlutterMapTileCaching.call].
class StoreDirectory {
  StoreDirectory._(this.storeName);

  /// The user-friendly name of the store directory
  final String storeName;

  /// Manage this store's representation on the filesystem
  ///
  /// Provides access to methods to:
  ///  * Create
  ///  * Delete
  ///  * Rename
  ///  * Reset
  StoreManagement get manage => StoreManagement._(this);

  /// Get statistics about this store
  StoreStats get stats => StoreStats._(this);

  /// Manage custom miscellaneous information tied to this store
  ///
  /// Uses a key-value format where both key and value must be [String]. More
  /// advanced requirements should use another package, as this is a basic
  /// implementation.
  StoreMetadata get metadata => StoreMetadata._(this);

  /// Provides export functionality for this store
  StoreExport get export => StoreExport._(this);

  /// Get tools to manage bulk downloading to this store
  DownloadManagement get download => DownloadManagement._(this);

  /// Get 'flutter_map_tile_caching's custom [TileProvider] for use in a
  /// [TileLayer], specific to this store
  ///
  /// Uses [FMTCSettings.defaultTileProviderSettings] by default (and it's
  /// default if unspecified). Alternatively, override [settings] for this get
  /// only.
  FMTCTileProvider getTileProvider([FMTCTileProviderSettings? settings]) =>
      FMTCTileProvider(storeDirectory: this, settings: settings);

  @override
  String toString() => 'StoreDirectory(storeName: $storeName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoreDirectory && other.storeName == storeName;
  }

  @override
  int get hashCode => storeName.hashCode;

  StoreDirectory copyWith(String? storeName) =>
      StoreDirectory._(storeName ?? this.storeName);
}
