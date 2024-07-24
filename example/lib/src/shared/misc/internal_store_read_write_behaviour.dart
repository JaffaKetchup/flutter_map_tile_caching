import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

/// Determines the read/update/create tile behaviour of a store
///
/// Expands [StoreReadWriteBehaviour].
enum InternalStoreReadWriteBehaviour {
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

  StoreReadWriteBehavior? toStoreReadWriteBehavior([
    StoreReadWriteBehavior? inheritableBehaviour,
  ]) =>
      switch (this) {
        disable => null,
        inherit => inheritableBehaviour,
        read => StoreReadWriteBehavior.read,
        readUpdate => StoreReadWriteBehavior.readUpdate,
        readUpdateCreate => StoreReadWriteBehavior.readUpdateCreate,
      };

  static InternalStoreReadWriteBehaviour fromStoreReadWriteBehavior(
    StoreReadWriteBehavior? behaviour,
  ) =>
      switch (behaviour) {
        null => InternalStoreReadWriteBehaviour.disable,
        StoreReadWriteBehavior.read => InternalStoreReadWriteBehaviour.read,
        StoreReadWriteBehavior.readUpdate =>
          InternalStoreReadWriteBehaviour.readUpdate,
        StoreReadWriteBehavior.readUpdateCreate =>
          InternalStoreReadWriteBehaviour.readUpdateCreate,
      };

  static const priority = [
    null,
    StoreReadWriteBehaviour.read,
    StoreReadWriteBehaviour.readUpdate,
    StoreReadWriteBehaviour.readUpdateCreate,
  ];
}
