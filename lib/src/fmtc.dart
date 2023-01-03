// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../flutter_map_tile_caching.dart';

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
  /// The directory which contains all databases required to use FMTC
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
  /// Prefer to leave [customRootDirectory] as `null`, which will use
  /// `getApplicationDocumentsDirectory()`. Alternativley, pass a custom
  /// directory - it is recommended to not use a cache directory, as the OS can
  /// clear these without notice at any time.
  ///
  /// You must construct using this before using [FlutterMapTileCaching.instance],
  /// otherwise a [StateError] will be thrown.
  ///
  /// This returns a configured [FlutterMapTileCaching], the same object as
  /// [FlutterMapTileCaching.instance]. Note that [FMTC] is an alias for this
  /// object.
  static Future<FlutterMapTileCaching> initialise({
    String? customRootDirectory,
    FMTCSettings? customSettings,
  }) async {
    final directory = await ((customRootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(customRootDirectory)) >>
            'fmtc')
        .create(recursive: true);
    final settings = customSettings ?? FMTCSettings();

    await FMTCRegistry.initialise(
      directory: directory,
      databaseMaxSize: settings.databaseMaxSize,
      databaseCompactCondition: settings.databaseCompactCondition,
    );
    return _instance = FMTC._(
      rootDirectory: RootDirectory._(directory),
      settings: settings,
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

  /// Get a [StoreDirectory] representation by store name, without creating it
  StoreDirectory call(String storeName) => StoreDirectory._(storeName);
}
