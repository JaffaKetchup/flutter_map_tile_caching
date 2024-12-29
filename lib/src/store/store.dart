// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

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
@immutable
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

  /// Generate an [FMTCTileProvider] that only specifies this store
  ///
  /// See other available [FMTCTileProvider] contructors to use multiple stores
  /// at once. See [FMTCTileProvider] for more info.
  ///
  /// [FMTCTileProvider.fakeNetworkDisconnect] cannot be set through this
  /// shorthand for [FMTCTileProvider.multipleStores].
  FMTCTileProvider getTileProvider({
    BrowseStoreStrategy storeStrategy = BrowseStoreStrategy.readUpdateCreate,
    BrowseStoreStrategy? otherStoresStrategy,
    BrowseLoadingStrategy loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    bool useOtherStoresAsFallbackOnly = false,
    bool recordHitsAndMisses = true,
    Duration cachedValidDuration = Duration.zero,
    UrlTransformer? urlTransformer,
    BrowsingExceptionHandler? errorHandler,
    ValueNotifier<TileLoadingInterceptorMap>? tileLoadingInterceptor,
    Map<String, String>? headers,
    Client? httpClient,
  }) =>
      FMTCTileProvider.multipleStores(
        storeNames: {storeName: storeStrategy},
        otherStoresStrategy: otherStoresStrategy,
        loadingStrategy: loadingStrategy,
        useOtherStoresAsFallbackOnly: useOtherStoresAsFallbackOnly,
        recordHitsAndMisses: recordHitsAndMisses,
        cachedValidDuration: cachedValidDuration,
        urlTransformer: urlTransformer,
        errorHandler: errorHandler,
        tileLoadingInterceptor: tileLoadingInterceptor,
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
