// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

import '../internal/tile_provider.dart';
import '../root/directory.dart';
import '../settings/fmtc_settings.dart';
import '../settings/tile_provider_settings.dart';
import 'access.dart';
import 'download.dart';
import 'export.dart';
import 'manage.dart';
import 'metadata.dart';
import 'statistics.dart';

/// Access point to a store
///
/// Contains access to:
/// * Statistics
/// * Management
/// * Low-Level Access (advanced)
///
/// A store is identified by it's validated store name (see [FMTCSettings.filesystemSanitiser] - an error is throw if the name is invalid), and represents a directory that resides within a [RootDirectory]. Each store contains multiple sub-directories.
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
  /// A store is identified by it's validated store name (see [FMTCSettings.filesystemSanitiser] - an error is throw if the name is invalid), and represents a directory that resides within a [RootDirectory]. Each store contains multiple sub-directories.
  ///
  /// Construction via this method automatically calls [StoreManagement.create] before returning (by default), so the caching directories will exist unless deleted using [StoreManagement.delete]. Disable this initialisation by setting [autoCreate] to `false`.
  @internal
  StoreDirectory(
    this.rootDirectory,
    this.storeName, {
    bool autoCreate = true,
  }) {
    if (autoCreate && !manage.ready) manage.create();
  }

  /// Get direct filesystem access paths for this store
  ///
  /// This should only be used in special cases, when modifying the store manually for example.
  StoreAccess get access => StoreAccess(this);

  /// Manage this store's representation on the filesystem
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

  /// Manage custom miscellaneous information tied to this store
  ///
  /// Uses a key-value format where both key and value must be [String]. There is no validation or sanitisation on any keys or values; note that keys form part of filenames.
  StoreMetadata get metadata => StoreMetadata(this);

  /// Provides export functionality for this store
  StoreExport get export => StoreExport(this);

  /// Get tools to manage bulk downloading to this store
  DownloadManagement get download => DownloadManagement(this);

  /// Get 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayer], specific to this store
  ///
  /// Uses [FMTCSettings.defaultTileProviderSettings] by default (and it's default if unspecified). Alternatively, override [settings] for this get only.
  FMTCTileProvider getTileProvider([FMTCTileProviderSettings? settings]) =>
      FMTCTileProvider(storeDirectory: this, settings: settings);

  @override
  String toString() =>
      'StoreDirectory(rootDirectory: $rootDirectory, storeName: $storeName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoreDirectory &&
        other.rootDirectory == rootDirectory &&
        other.storeName == storeName;
  }

  @override
  int get hashCode => rootDirectory.hashCode ^ storeName.hashCode;

  StoreDirectory copyWith({
    RootDirectory? rootDirectory,
    String? storeName,
  }) =>
      StoreDirectory(
        rootDirectory ?? this.rootDirectory,
        storeName ?? this.storeName,
      );
}
