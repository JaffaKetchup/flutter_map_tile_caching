// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'root/directory.dart';
import 'settings/fmtc_settings.dart';
import 'store/directory.dart';

/// Direct alias of [FlutterMapTileCaching] for easier development
///
/// Prefer use of full 'FlutterMapTileCaching' when initialising to ensure
/// readability and understanding in other code.
typedef FMTC = FlutterMapTileCaching;

/// Main singleton access point for 'flutter_map_tile_caching'
///
/// You must construct using [FlutterMapTileCaching.initialise] before using
/// [FlutterMapTileCaching.instance], otherwise a [StateError] will be thrown.
/// Note that the singleton can be re-initialised/changed by calling the
/// aforementioned constructor again.
///
/// [FMTC] is an alias for this object.
class FlutterMapTileCaching {
  /// The cache's root directory
  ///
  /// See [initialise]'s documentation for more information
  final RootDirectory rootDirectory;

  /// Custom global 'flutter_map_tile_caching' settings
  ///
  /// See [FMTCSettings]' properties for more information
  final FMTCSettings settings;

  /// Internal constructor, to be used by [initialise]
  FlutterMapTileCaching._({
    required this.rootDirectory,
    required this.settings,
  });

  /// Initialise and prepare FMTC, by creating all neccessary directories/files
  /// and configuring the [FlutterMapTileCaching] singleton
  ///
  /// You must construct using this before using [FlutterMapTileCaching.instance],
  /// otherwise a [StateError] will be thrown.
  ///
  /// This returns a configured [FlutterMapTileCaching], the same object as
  /// [FlutterMapTileCaching.instance]. Note that [FMTC] is an alias for this
  /// object.
  static Future<FlutterMapTileCaching> initialise(
    RootDirectory rootDirectory, {
    FMTCSettings? settings,
  }) async {
    await rootDirectory.manage.createAsync();
    return _instance = FMTC._(
      rootDirectory: rootDirectory,
      settings: settings ?? FMTCSettings(),
    );
  }

  /// The singleton instance of [FlutterMapTileCaching] at call time
  ///
  /// Must not be read or written directly, except in
  /// [FlutterMapTileCaching.instance] and [FlutterMapTileCaching.initialise]
  /// respectively.
  static FlutterMapTileCaching? _instance;

  /// Get the configured instance of [FlutterMapTileCaching], after
  /// [FlutterMapTileCaching.initialise] has been called, for further actions
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
  /// Automatically creates the appropriate store **synchronously**, unlike `()`.
  /// Prefer [call] wherever possible.
  StoreDirectory operator [](String storeName) =>
      StoreDirectory(rootDirectory, storeName);

  /// Get a [StoreDirectory] by store name
  ///
  /// Does not automatically create the appropriate store, unlike `[]`.
  /// Therefore, use `.manage.createAsync()` afterward if necessary.
  StoreDirectory call(String storeName) =>
      StoreDirectory(rootDirectory, storeName, autoCreate: false);
}
