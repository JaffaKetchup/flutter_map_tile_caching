// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Represents a store of tiles
///
/// The tile store itself is a database containing a descriptor, tiles and
/// metadata.
///
/// The name originates from previous versions of this library, where it
/// represented a real directory instead of a database.
///
/// Reach through [FlutterMapTileCaching.call].
class StoreDirectory {
  StoreDirectory._(
    this.storeName, {
    required bool autoCreate,
  }) {
    if (autoCreate) manage.create();
  }

  /// The user-friendly name of the store directory
  final String storeName;

  /// Manage this store's representation on the filesystem
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
  ///
  /// The 'fmtc_plus_sharing' module must be installed to add the functionality,
  /// without it, this object provides no functionality.
  StoreExport get export => StoreExport._(this);

  /// Get tools to manage bulk downloading to this store
  ///
  /// The 'fmtc_plus_background_downloading' module must be installed to add the
  /// background downloading functionality.
  DownloadManagement get download => DownloadManagement._(this);

  /// Get the [TileProvider] suitable to connect the [TileLayer] to FMTC's
  /// internals
  ///
  /// Uses [FMTCSettings.defaultTileProviderSettings] by default (and it's
  /// default if unspecified). Alternatively, override [settings] for this get
  /// only.
  FMTCTileProvider getTileProvider([
    FMTCTileProviderSettings? settings,
    Map<String, String>? headers,
    BaseClient? httpClient,
  ]) =>
      FMTCTileProvider._(
        storeDirectory: this,
        settings: settings,
        headers: headers ?? {},
        httpClient: httpClient,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreDirectory && other.storeName == storeName);

  @override
  int get hashCode => storeName.hashCode;
}
