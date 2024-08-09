import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

/// Determines the read/update/create tile behaviour of a store
///
/// Expands [BrowseStoreStrategy].
enum InternalBrowseStoreStrategy {
  /// Disable store entirely
  disable,

  /// Inherit from general setting
  inherit,

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
  readUpdateCreate;

  BrowseStoreStrategy? toBrowseStoreStrategy([
    BrowseStoreStrategy? inheritableBehaviour,
  ]) =>
      switch (this) {
        disable => null,
        inherit => inheritableBehaviour,
        read => BrowseStoreStrategy.read,
        readUpdate => BrowseStoreStrategy.readUpdate,
        readUpdateCreate => BrowseStoreStrategy.readUpdateCreate,
      };

  static InternalBrowseStoreStrategy fromBrowseStoreStrategy(
    BrowseStoreStrategy? behaviour,
  ) =>
      switch (behaviour) {
        null => InternalBrowseStoreStrategy.disable,
        BrowseStoreStrategy.read => InternalBrowseStoreStrategy.read,
        BrowseStoreStrategy.readUpdate =>
          InternalBrowseStoreStrategy.readUpdate,
        BrowseStoreStrategy.readUpdateCreate =>
          InternalBrowseStoreStrategy.readUpdateCreate,
      };

  static const priority = [
    null,
    BrowseStoreStrategy.read,
    BrowseStoreStrategy.readUpdate,
    BrowseStoreStrategy.readUpdateCreate,
  ];
}
