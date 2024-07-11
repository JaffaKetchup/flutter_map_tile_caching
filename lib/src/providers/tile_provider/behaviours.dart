// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Alias of [CacheBehavior]
///
/// ... with the correct spelling :D
typedef CacheBehaviour = CacheBehavior;

/// Behaviours dictating how and when browse caching should occur
///
/// | `CacheBehavior`          | Preferred fetch method | Fallback fetch method |
/// |--------------------------|------------------------|-----------------------|
/// | `cacheOnly`              | Cache                  | None                  |
/// | `cacheFirst`             | Cache                  | Network               |
/// | `onlineFirst`            | Network                | Cache                 |
/// | *Standard Tile Provider* | *Network*              | *None*                |
enum CacheBehavior {
  /// Only fetch tiles from the local cache
  ///
  /// In this mode, [StoreReadWriteBehavior] is irrelevant.
  ///
  /// Throws [FMTCBrowsingErrorType.missingInCacheOnlyMode] if a tile is
  /// unavailable.
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheOnly,

  /// Fetch tiles from the cache, falling back to the network to fetch and
  /// create/update non-existent/expired tiles, dependent on the selected
  /// [StoreReadWriteBehavior]
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheFirst,

  /// Fetch and create/update non-existent/expired tiles from the network,
  /// falling back to the cache to fetch tiles, dependent on the selected
  /// [StoreReadWriteBehavior]
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  onlineFirst,
}

/// Alias of [StoreReadWriteBehavior]
///
/// ... with the correct spelling :D
typedef StoreReadWriteBehaviour = StoreReadWriteBehavior;

/// Determines the read/update/create tile behaviour of a store
enum StoreReadWriteBehavior {
  /// Only read tiles
  read,

  /// Read tiles, and also update existing tiles
  ///
  /// Unlike 'create', if (an older version of) a tile does not already exist in
  /// the store, it will not be written.
  readUpdate,

  /// Read, update, and create tiles
  ///
  /// See [readUpdate] for a definition of 'update'.
  readUpdateCreate,
}
