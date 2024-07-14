// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Information useful to debug and record detailed statistics for the loading
/// mechanisms and paths of a tile
///
/// When an object of this type is emitted through a [TileLoadingDebugMap], the
/// tile will have finished loading (successfully or unsuccessfully), and all
/// fields/properties will be initialised and safe to read.
class TileLoadingDebugInfo {
  TileLoadingDebugInfo._();

  /// Indicates whether & how the tile completed loading successfully
  ///
  /// If `null`, loading was unsuccessful. Otherwise, the
  /// [TileLoadingDebugResultPath] indicates the final path point of how the
  /// tile was output.
  ///
  /// See [didComplete] for a boolean result. If `null`, see [error] for the
  /// error/exception object.
  late final TileLoadingDebugResultPath? result;

  /// Indicates whether & how the tile completed loading unsuccessfully
  ///
  /// If `null`, loading was successful. Otherwise, the object is the
  /// error/exception thrown whilst loading the tile - which is likely to be an
  /// [FMTCBrowsingError].
  ///
  /// See [didComplete] for a boolean result. If `null`, see [result] for the
  /// exact result path.
  late final Object? error;

  /// Indicates whether the tile completed loading successfully
  ///
  /// * `true`:  completed - see [result] for exact result path
  /// * `false`: errored - see [error] for error/exception object
  bool get didComplete => result != null;

  /// The requested URL of the tile (based on the [TileLayer.urlTemplate])
  late final String networkUrl;

  /// The storage-suitable UID of the tile: the result of
  /// [FMTCTileProviderSettings.urlTransformer] on [networkUrl]
  late final String storageSuitableUID;

  /// If the tile already existed, the stores that it existed in/belonged to
  late final List<String>? existingStores;

  /// Reflection of an internal indicator of the same name
  ///
  /// Calculated with:
  ///
  /// ```dart
  /// <whether the tile already existed> &&
  /// `useOtherStoresAsFallbackOnly` &&
  /// <whether the union of the specified `storeNames` and `existingStores` is empty>
  /// ```
  late final bool tileExistsInUnspecifiedStoresOnly;

  /// Reflection of an internal indicator of the same name
  ///
  /// Calculated with:
  ///
  /// ```dart
  /// <whether the tile already existed> &&
  /// (
  ///   'behavior' == CacheBehavior.onlineFirst ||
  ///   <whether the existing tile had expired>
  /// )
  /// ```
  late final bool needsUpdating;

  /// Whether a hit or miss was (or would have) been recorded
  late final bool hitOrMiss;

  /// A mapping of all stores the tile was written to, to whether that tile was
  /// newly created in that store (not updated)
  ///
  /// `null` if no write operation was necessary/attempted.
  late final Future<Map<String, bool>>? writeResult;
}
