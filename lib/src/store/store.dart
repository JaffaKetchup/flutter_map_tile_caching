// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: use_late_for_private_fields_and_variables

part of '../../flutter_map_tile_caching.dart';

/// {@template fmtc.fmtcStore}
/// Provides access to management, statistics, metadata, bulk download,
/// the tile provider (and the export functionality) on the store named
/// [storeName]
///
/// > [!IMPORTANT]
/// > Constructing an instance of this class will not automatically create it.
/// > To create this store, use [manage] > [StoreManagement.create].
/// {@endtemplate}
class FMTCStore {
  /// {@macro fmtc.fmtcStore}
  const FMTCStore(this.storeName);

  /// The user-friendly name of the store directory
  final String storeName;

  /// Manage this store's representation on the filesystem
  StoreManagement get manage => StoreManagement._(storeName);

  /// Get statistics about this store
  StoreStats get stats => StoreStats._(storeName);

  /// Manage custom miscellaneous information tied to this store
  ///
  /// Uses a key-value format where both key and value must be [String]. More
  /// advanced requirements should use another package, as this is a basic
  /// implementation.
  StoreMetadata get metadata => StoreMetadata._(storeName);

  /// Provides bulk downloading functionality
  StoreDownload get download => StoreDownload._(storeName);

  /// Generate a [TileProvider] that connects to FMTC internals
  ///
  /// [settings] defaults to the current ambient
  /// [FMTCTileProviderSettings.instance], which defaults to the initial
  /// configuration if no other instance has been set.
  ///
  /// See other available [FMTCTileProvider] contructors to use multiple stores
  /// at once.
  FMTCTileProvider getTileProvider({
    StoreReadWriteBehavior readWriteBehavior =
        StoreReadWriteBehavior.readUpdateCreate,
    StoreReadWriteBehavior? otherStoresBehavior,
    FMTCTileProviderSettings? settings,
    ValueNotifier<TileLoadingDebugMap>? tileLoadingDebugger,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) =>
      FMTCTileProvider.multipleStores(
        storeNames: {storeName: readWriteBehavior},
        otherStoresBehavior: otherStoresBehavior,
        settings: settings,
        tileLoadingDebugger: tileLoadingDebugger,
        headers: headers,
        httpClient: httpClient,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCStore && other.storeName == storeName);

  @override
  int get hashCode => storeName.hashCode;

  @override
  String toString() => 'FMTCStore(storeName: $storeName)';
}
