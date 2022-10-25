// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'root/directory.dart';
import 'root/manage.dart';
import 'settings/fmtc_settings.dart';
import 'store/directory.dart';

/// Direct alias of [FlutterMapTileCaching] for easier development
///
/// Prefer use of full 'FlutterMapTileCaching' when initialising to ensure readability and understanding in other code.
typedef FMTC = FlutterMapTileCaching;

/// Main singleton access point for 'flutter_map_tile_caching'
///
/// You must construct using [FlutterMapTileCaching.initialise] before using [FlutterMapTileCaching.instance], otherwise a [StateError] will be thrown. Note that the singleton can be re-initialised/changed by calling the aforementioned constructor again.
///
/// [FMTC] is an alias for this object.
class FlutterMapTileCaching {
  /// The cache's root
  ///
  /// Recommended setup is `await RootDirectory.normalCache`, but any [RootDirectory] is accepted. [FlutterMapTileCaching] checks that [RootManagement.ready] is 'true', otherwise a [StateError] is thrown.
  late final RootDirectory rootDirectory;

  /// Custom global 'flutter_map_tile_caching' settings
  ///
  /// See [FMTCSettings]' properties for more information
  final FMTCSettings settings;

  /// Initialise the main singleton access point for 'flutter_map_tile_caching'
  ///
  /// You must construct using this before using [FlutterMapTileCaching.instance], otherwise a [StateError] will be thrown. Note that the singleton can be re-initialised/changed by calling this constructor again.
  ///
  /// This returns the same object as [FlutterMapTileCaching.instance] will afterward. [FMTC] is an alias for this object.
  FlutterMapTileCaching.initialise(
    RootDirectory rootDir, {
    FMTCSettings? settings,
  }) : settings = settings ?? FMTCSettings() {
    if (!rootDir.manage.ready) {
      throw StateError(
        'Supplied root directory does not exist. Try constructing it again, or using `rootDirectory.manage.create()`.',
      );
    }
    rootDirectory = rootDir;
    _instance = this;
  }

  /// The singleton instance of [FlutterMapTileCaching] at call time
  ///
  /// Must not be read or written directly, except in [FlutterMapTileCaching.instance] and [FlutterMapTileCaching.initialise] respectively.
  static FlutterMapTileCaching? _instance;

  /// Get the configured instance of [FlutterMapTileCaching], after [FlutterMapTileCaching.initialise] has been called, for further actions
  static FlutterMapTileCaching get instance {
    if (_instance == null) {
      throw StateError(
        'Use `FlutterMapTileCaching.initialise()` before getting `FlutterMapTileCaching.instance`.',
      );
    }

    return _instance!;
  }

  /// Get a [StoreDirectory] by store name
  ///
  /// Automatically creates the appropriate store synchronously, unlike `()`.
  StoreDirectory operator [](String storeName) =>
      StoreDirectory(rootDirectory, storeName);

  /// Get a [StoreDirectory] by store name
  ///
  /// Does not automatically create the appropriate store, unlike `[]`. Therefore, use `.manage.createAsync()` afterward if necessary.
  StoreDirectory call(String storeName) =>
      StoreDirectory(rootDirectory, storeName, autoCreate: false);
}
