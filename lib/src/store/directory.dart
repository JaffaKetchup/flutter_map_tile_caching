// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Equivalent to [FMTCStore], provided to ease migration only
///
/// The name refers to earlier versions of this library where the filesystem
/// was used for storage, instead of a database.
///
/// This deprecation typedef will be removed in a future release: migrate to
/// [FMTCStore].
@Deprecated(
  '''
Migrate to `FMTCStore`. This deprecation typedef is provided to ease migration 
only. It will be removed in a future version.
''',
)
typedef StoreDirectory = FMTCStore;

/// Provides access to management, statistics, metadata, bulk download,
/// the tile provider (and the export functionality) on the store named
/// [storeName]
///
/// {@template fmtc.fmtcstore.sub.noautocreate}
/// Note that constructing an instance of this class will not automatically
/// create it, as this is an asynchronous operation. To create this store, use
/// [manage] > [StoreManagement.create].
/// {@endtemplate}
class FMTCStore {
  /// Provides access to management, statistics, metadata, bulk download,
  /// the tile provider (and the export functionality) on the store named
  /// [storeName]
  ///
  /// {@macro fmtc.fmtcstore.sub.noautocreate}
  const FMTCStore(this.storeName);

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
  FMTCTileProvider getTileProvider({
    FMTCTileProviderSettings? settings,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) =>
      FMTCTileProvider._(
        this,
        settings: settings,
        headers: headers ?? {},
        httpClient: httpClient,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCStore && other.storeName == storeName);

  @override
  int get hashCode => storeName.hashCode;
}
