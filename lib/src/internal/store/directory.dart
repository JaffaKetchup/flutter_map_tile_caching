import 'package:flutter_map/flutter_map.dart';

import '../../misc/validate.dart';
import '../../root/directory.dart';
import 'access.dart';
import 'manage.dart';
import 'statistics.dart';
import 'tile_provider.dart';

/// Access point to a store
///
/// Contains access to:
/// * Statistics
/// * Management
/// * Low-Level Access (advanced)
///
/// A store is identified by it's validated store name (see [safeFilesystemString] - an error is throw if the name is invalid), and represents a directory that resides within a [RootDirectory]. Each store contains multiple sub-directories.
class StoreDirectory {
  /// The container for all files used within this library
  final RootDirectory rootDirectory;

  /// The user-friendly name of the store directory
  final String storeName;

  /// Creates an access point to a store
  ///
  /// Contains access to:
  /// * Statistics
  /// * Management
  /// * Low-Level Access (advanced)
  ///
  /// A store is identified by it's validated store name (see [safeFilesystemString] - an error is throw if the name is invalid), and represents a directory that resides within a [RootDirectory]. Each store contains multiple sub-directories.
  ///
  /// Construction via this method automatically calls [StoreManagement.create] before returning (by default), so the caching directories will exist unless deleted using [StoreManagement.delete]. Disable this initialisation by setting [autoCreate] to `false`.
  StoreDirectory(
    this.rootDirectory,
    this.storeName, {
    bool autoCreate = true,
  }) {
    if (autoCreate) manage.create();
  }

  /// Check whether all directories exist synchronously
  bool get ready => [
        access.tiles.existsSync(),
        access.stats.existsSync(),
        access.metadata.existsSync(),
      ].every((e) => e);

  /// Check whether all directories exist asynchronously
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        access.tiles.exists(),
        access.stats.exists(),
        access.metadata.exists(),
      ]))
          .every((e) => e);

  /// Get direct filesystem access paths
  ///
  /// This should only be used in special cases, when modifying the store manually for example.
  StoreAccess get access => StoreAccess(this);

  /// Manage the store's representation on the filesystem
  ///
  /// Provides access to methods to:
  ///  * Create
  ///  * Delete
  ///  * Rename
  ///  * Reset
  StoreManagement get manage => StoreManagement(this);

  /// Get statistics about this store
  ///
  /// Does not statistics about the root/all stores
  StoreStats get stats => StoreStats(this);

  /// Get 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayerOptions], specific to this store
  FMTCTileProvider getTileProvider({FMTCTileProviderSettings? settings}) =>
      FMTCTileProvider(storeDirectory: this, settings: settings);

  @override
  String toString() {
    return 'StoreDirectory(rootDirectory: $rootDirectory, storeName: $storeName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoreDirectory &&
        other.rootDirectory == rootDirectory &&
        other.storeName == storeName;
  }

  @override
  int get hashCode {
    return rootDirectory.hashCode ^ storeName.hashCode;
  }

  StoreDirectory copyWith({
    RootDirectory? rootDirectory,
    String? storeName,
  }) =>
      StoreDirectory(
        rootDirectory ?? this.rootDirectory,
        storeName ?? this.storeName,
      );
}
