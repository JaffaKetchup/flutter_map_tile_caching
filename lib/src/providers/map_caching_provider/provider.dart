import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../flutter_map_tile_caching.dart';
import '../../backend/export_internal.dart';

@immutable
class FMTCCachingProvider implements MapCachingProvider, PutTileCapability {
  /// Create an [FMTCTileProvider] that interacts with a subset of all available
  /// stores
  ///
  /// See [stores] & [otherStoresStrategy] for information.
  ///
  /// {@macro fmtc.fmtcTileProvider.constructionTip}
  const FMTCCachingProvider({
    required this.stores,
    this.otherStoresStrategy,
    this.loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    this.useOtherStoresAsFallbackOnly = false,
    this.cachedValidDuration = Duration.zero,
    this.tileKeyGenerator = BuiltInMapCachingProvider.uuidTileKeyGenerator,
  });

  /// Create an [FMTCTileProvider] that interacts with all available stores,
  /// using one [BrowseStoreStrategy] efficiently
  ///
  /// {@macro fmtc.fmtcTileProvider.constructionTip}
  const FMTCCachingProvider.allStores({
    required BrowseStoreStrategy allStoresStrategy,
    this.loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    this.cachedValidDuration = Duration.zero,
    this.tileKeyGenerator = BuiltInMapCachingProvider.uuidTileKeyGenerator,
  })  : stores = const {},
        otherStoresStrategy = allStoresStrategy,
        useOtherStoresAsFallbackOnly = false;

  /// The store names from which to (possibly) read/update/create tiles from/in
  ///
  /// Keys represent store names, and the associated [BrowseStoreStrategy]
  /// represents how that store should be used.
  ///
  /// Stores not included will not be used by default. However,
  /// [otherStoresStrategy] determines whether & how all other unspecified
  /// stores should be used. Stores included in this mapping but with a `null`
  /// value will be exempted from [otherStoresStrategy] (ie. unused).
  ///
  /// All specified store names should correspond to existing stores.
  /// Non-existant stores may cause unexpected read behaviour and will throw a
  /// [StoreNotExists] error if a tile is attempted to be written to it.
  final Map<String, BrowseStoreStrategy?> stores;

  /// The behaviour of all other stores not specified in [stores]
  ///
  /// `null` means that all other stores will not be used.
  ///
  /// Setting a non-`null` value may negatively impact performance, because
  /// internal tile cache lookups will have less constraints.
  ///
  /// Also see [useOtherStoresAsFallbackOnly] for whether these unspecified
  /// stores should only be used as a last resort or in addition to the
  /// specified stores as normal.
  ///
  /// Stores specified in [stores] but associated with a `null` value will not
  /// gain this behaviour.
  final BrowseStoreStrategy? otherStoresStrategy;

  /// Determines whether the network or cache is preferred during browse
  /// caching, and how to fallback
  ///
  /// Defaults to [BrowseLoadingStrategy.cacheFirst].
  final BrowseLoadingStrategy loadingStrategy;

  /// Whether to only use tiles retrieved by
  /// [FMTCTileProvider.otherStoresStrategy] after all specified stores have
  /// been exhausted (where the tile was not present)
  ///
  /// When tiles are retrieved from other stores, it is counted as a miss for
  /// the specified store(s).
  ///
  /// Note that an attempt is *always* made to read the tile from the cache,
  /// regardless of whether the tile is then actually retrieved from the cache
  /// or the network is then used (successfully).
  ///
  /// For example, if a specified store does not contain the tile, and an
  /// unspecified store does contain the tile:
  ///  * if this is `false`, then the tile will be retrieved and used from the
  /// unspecified store
  ///  * if this is `true`, then the tile will be retrieved (see note above),
  /// but not used unless the network request fails
  ///
  /// Defaults to `false`.
  final bool useOtherStoresAsFallbackOnly;

  /// The duration for which a tile does not require updating when cached, after
  /// which it is marked as expired and updated at the next possible
  /// opportunity
  ///
  /// Set to [Duration.zero] to never expire a tile (default).
  final Duration cachedValidDuration;

  /// Function to convert a tile's URL to a key used to uniquely identify the
  /// tile
  ///
  /// Where parts of the URL are volatile or do not represent the tile's
  /// contents/image - for example, API keys contained with the query
  /// parameters - this should be modified to remove the volatile portions.
  ///
  /// Keys must be usable as filenames on all intended platform filesystems.
  /// The callback should not throw.
  ///
  /// Defaults to using [BuiltInMapCachingProvider.uuidTileKeyGenerator].
  final String Function(String url) tileKeyGenerator;

  /// Compile the [FMTCTileProvider.stores] &
  /// [FMTCTileProvider.otherStoresStrategy] into a format which can be resolved
  /// by the backend once all available stores are known
  ({List<String> storeNames, bool includeOrExclude}) _compileReadableStores() {
    final excludeOrInclude = otherStoresStrategy != null;
    final storeNames = (excludeOrInclude
            ? stores.entries.where((e) => e.value == null)
            : stores.entries.where((e) => e.value != null))
        .map((e) => e.key)
        .toList(growable: false);
    return (storeNames: storeNames, includeOrExclude: !excludeOrInclude);
  }

  @override
  Future<CachedMapTile<CachedTileMetadata>?> getTile(String url) async {
    final storageSuitableUid = tileKeyGenerator(url);

    final (
      tile: existingTile,
      intersectedStoreNames: intersectedExistingStores, //! TODO
      allStoreNames: allExistingStores,
    ) = await FMTCBackendAccess.internal.readTile(
      url: storageSuitableUid,
      storeNames: _compileReadableStores(),
    );

    if (existingTile != null) {
      final bytes = existingTile.bytes;

      if (loadingStrategy == BrowseLoadingStrategy.cacheOnly) {
        // We can't use the network, so always use the tile regardless of its
        // status
        return (bytes: bytes, metadata: CachedTileMetadata.fresh);
      }

      if (loadingStrategy == BrowseLoadingStrategy.onlineFirst) {
        // Prefer using the network, but use the cached tile as a fallback if
        // necessary
        return (bytes: bytes, metadata: CachedTileMetadata.stale);
      }

      // Loading strategy is cache first
      // Here, we want to try to use the network (falling back to the cached
      // tile), only if either:
      //  * the tile was retrieved from an "other" store, and
      //    `useOtherStoresAsFallbackOnly` was set
      //  * the tile has expired and needs updating
      // Otherwise, we use the cached tile

      if (useOtherStoresAsFallbackOnly &&
          stores.keys.toSet().intersection(allExistingStores.toSet()).isEmpty) {
        return (bytes: bytes, metadata: CachedTileMetadata.stale);
      }
      if (cachedValidDuration != Duration.zero &&
          DateTime.timestamp().millisecondsSinceEpoch -
                  existingTile.lastModified.millisecondsSinceEpoch >
              cachedValidDuration.inMilliseconds) {
        return (bytes: bytes, metadata: CachedTileMetadata.stale);
      }
      return (bytes: bytes, metadata: CachedTileMetadata.fresh);
    }

    if (loadingStrategy == BrowseLoadingStrategy.cacheOnly) {
      throw FMTCBrowsingError(
        type: FMTCBrowsingErrorType.missingInCacheOnlyMode,
        networkUrl: url,
        storageSuitableUID: storageSuitableUid,
      );
    }

    return null; // Depend on network
  }

  @override
  // TODO: implement isSupported
  bool get isSupported => throw UnimplementedError();

  @override
  Future<void> putTile({
    required String url,
    Uint8List? bytes,
  }) {
    // TODO: implement putTile
    throw UnimplementedError();
  }
}
