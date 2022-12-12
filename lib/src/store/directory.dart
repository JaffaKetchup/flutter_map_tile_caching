// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../fmtc.dart';

/// Represents a store of tiles
///
/// The tile store itself is a database referred to in the registry
/// (see [FMTCRegistry]).
///
/// The name originates from previous versions of this library, where it
/// represented a real directory instead of a database.
///
/// Reach through [FlutterMapTileCaching.call].
@internal
class StoreDirectory {
  StoreDirectory._(this.storeName);

  /// The user-friendly name of the store directory
  final String storeName;

  /// Get direct filesystem access paths for this store
  ///
  /// This should only be used in special cases, when modifying the store manually for example.
  //StoreAccess get access => StoreAccess(this);

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
  /// Uses a key-value format where both key and value must be [String]. There is no validation or sanitisation on any keys or values; note that keys form part of filenames.
  //StoreMetadata get metadata => StoreMetadata(this);

  /// Provides export functionality for this store
  //StoreExport get export => StoreExport(this);

  /// Get tools to manage bulk downloading to this store
  //DownloadManagement get download => DownloadManagement(this);

  /// Get 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayer], specific to this store
  ///
  /// Uses [FMTCSettings.defaultTileProviderSettings] by default (and it's default if unspecified). Alternatively, override [settings] for this get only.
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

  StoreDirectory copyWith({
    RootDirectory? rootDirectory,
    String? storeName,
  }) =>
      StoreDirectory._(storeName ?? this.storeName);
}
