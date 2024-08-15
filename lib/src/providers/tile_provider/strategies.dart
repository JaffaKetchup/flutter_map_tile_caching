// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Alias for [BrowseLoadingStrategy], to ease migration from v9 -> v10
@Deprecated('`CacheBehavior` has been renamed to `BrowseLoadingStrategy`')
typedef CacheBehavior = BrowseLoadingStrategy;

/// Determines whether the network or cache is preferred during browse caching,
/// and how to fallback
///
/// | `BrowseLoadingStrategy`  | Preferred method       | Fallback method       |
/// |--------------------------|------------------------|-----------------------|
/// | `cacheOnly`              | Cache                  | None                  |
/// | `cacheFirst`             | Cache                  | Network               |
/// | `onlineFirst`            | Network                | Cache                 |
/// | *Standard Tile Provider* | *Network*              | *None*                |
enum BrowseLoadingStrategy {
  /// Only fetch tiles from the local cache
  ///
  /// In this mode, [BrowseStoreStrategy] is irrelevant.
  ///
  /// Throws [FMTCBrowsingErrorType.missingInCacheOnlyMode] if a tile is
  /// unavailable.
  ///
  /// See documentation on [BrowseLoadingStrategy] for a strategy comparison
  /// table.
  cacheOnly,

  /// Fetch tiles from the cache, falling back to the network to fetch and
  /// create/update non-existent/expired tiles, dependent on the selected
  /// [BrowseStoreStrategy]
  ///
  /// See documentation on [BrowseLoadingStrategy] for a strategy comparison
  /// table.
  cacheFirst,

  /// Fetch and create/update non-existent/expired tiles from the network,
  /// falling back to the cache to fetch tiles, dependent on the selected
  /// [BrowseStoreStrategy]
  ///
  /// See documentation on [BrowseLoadingStrategy] for a strategy comparison
  /// table.
  onlineFirst,
}

/// Determines when tiles should be written to a store during browse caching
enum BrowseStoreStrategy {
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
