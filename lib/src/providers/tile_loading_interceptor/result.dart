// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// A 'temporary' object that collects information from [_internalGetBytes] to
/// be used to construct a [TileLoadingInterceptorResult]
///
/// See documentation on [TileLoadingInterceptorResult] for more information
class _TLIRConstructor {
  _TLIRConstructor._();

  TileLoadingInterceptorResultPath? resultPath;
  ({Object error, StackTrace stackTrace})? error;
  late String networkUrl;
  late String storageSuitableUID;
  List<String>? existingStores;
  late bool tileRetrievableFromOtherStoresAsFallback;
  late bool needsUpdating;
  bool? hitOrMiss;
  Future<Map<String, bool>>? storesWriteResult;
  late Duration cacheFetchDuration;
  Duration? networkFetchDuration;
}

/// Information useful to debug and record detailed statistics for the loading
/// mechanisms and paths of a tile
@immutable
class TileLoadingInterceptorResult {
  const TileLoadingInterceptorResult._({
    required this.resultPath,
    required this.error,
    required this.networkUrl,
    required this.storageSuitableUID,
    required this.existingStores,
    required this.tileRetrievedFromOtherStoresAsFallback,
    required this.needsUpdating,
    required this.hitOrMiss,
    required this.storesWriteResult,
    required this.cacheFetchDuration,
    required this.networkFetchDuration,
  });

  /// Indicates whether & how the tile completed loading successfully
  ///
  /// If `null`, loading was unsuccessful. Otherwise, the
  /// [TileLoadingInterceptorResultPath] indicates the final path point of how
  /// the tile was output.
  ///
  /// See [didComplete] for a boolean result. If `null`, see [error] for the
  /// error/exception object.
  final TileLoadingInterceptorResultPath? resultPath;

  /// Indicates whether & how the tile completed loading unsuccessfully
  ///
  /// If `null`, loading was successful. Otherwise, the object is the
  /// error/exception thrown whilst loading the tile - which is likely to be an
  /// [FMTCBrowsingError].
  ///
  /// See [didComplete] for a boolean result. If `null`, see [resultPath] for the
  /// exact result path.
  final ({Object error, StackTrace stackTrace})? error;

  /// Indicates whether the tile completed loading successfully
  ///
  /// * `true`:  completed - see [resultPath] for exact result path
  /// * `false`: errored - see [error] for error/exception object
  bool get didComplete => resultPath != null;

  /// The requested URL of the tile (based on the [TileLayer.urlTemplate])
  final String networkUrl;

  /// The storage-suitable UID of the tile: the result of
  /// [FMTCTileProvider.urlTransformer] on [networkUrl]
  final String storageSuitableUID;

  /// If the tile already existed, the stores that it existed in/belonged to
  final List<String>? existingStores;

  /// Whether the tile was retrieved and used from an unspecified store as a
  /// fallback
  ///
  /// Note that an attempt is *always* made to read the tile from the cache,
  /// regardless of whether the tile is then actually retrieved from the cache
  /// or the network is then used (successfully).
  ///
  /// Calculated with:
  ///
  /// ```
  /// `useOtherStoresAsFallbackOnly` &&
  /// `resultPath` == TileLoadingInterceptorResultPath.cacheAsFallback &&
  /// <whether the tile already existed> &&
  /// <whether the intersection of the specified `storeNames` and `existingStores` is empty>
  /// ```
  final bool tileRetrievedFromOtherStoresAsFallback;

  /// Whether the tile was indicated for updating (excluding creating)
  ///
  /// Calculated with:
  ///
  /// ```
  /// <whether the tile already existed> &&
  /// (
  ///   `loadingStrategy` == BrowseLoadingStrategy.onlineFirst ||
  ///   <whether the existing tile had expired>
  /// )
  /// ```
  final bool needsUpdating;

  /// Whether a hit or miss was (or would have) been recorded
  ///
  /// `null` if the tile did not complete loading successfully.
  final bool? hitOrMiss;

  /// A mapping of all stores the tile was written to, to whether that tile was
  /// newly created in that store (not updated)
  ///
  /// Is a future because the result must come from an asynchronously triggered
  /// database write operation.
  ///
  /// `null` if no write operation was necessary/attempted, or the tile did not
  /// complete loading successfully.
  final Future<Map<String, bool>>? storesWriteResult;

  /// The duration of the operation used to attempt to read the existing tile
  /// from the store/cache
  ///
  /// Note that even in [BrowseLoadingStrategy.onlineFirst] and where the tile
  /// is not used from the local store/cache, an attempt is *always* made to
  /// read the tile from the cache.
  final Duration cacheFetchDuration;

  /// The duration of the operation used to attempt to fetch the tile from the
  /// network.
  ///
  /// `null` if no network fetch was attempted, or the tile did not complete
  /// loading successfully.
  final Duration? networkFetchDuration;
}
