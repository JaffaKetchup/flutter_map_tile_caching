// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

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

  /// Whether FMTC should perform extra reporting and console logging
  ///
  /// Depends on [_debugMode] (set via [initialise]) and [kDebugMode].
  bool get debugMode => _debugMode && kDebugMode;
  final bool _debugMode;

  /// Internal constructor, to be used by [initialise]
  const FlutterMapTileCaching._({
    required this.rootDirectory,
    required this.settings,
    required bool debugMode,
  }) : _debugMode = debugMode;

  /// {@macro fmtc.backend.initialise}
  ///
  /// Initialise and prepare FMTC, by creating all necessary directories/files
  /// and configuring the [FlutterMapTileCaching] singleton
  ///
  /// Prefer to leave [rootDirectory] as `null`, which will use
  /// `getApplicationDocumentsDirectory()`. Alternatively, pass a custom
  /// directory - it is recommended to not use a cache directory, as the OS can
  /// clear these without notice at any time.
  ///
  /// You must construct using this before using [FlutterMapTileCaching.instance],
  /// otherwise a [StateError] will be thrown.
  ///
  /// The initialisation safety system ensures that a corrupted database cannot
  /// prevent the app from launching. However, one fatal crash is necessary for
  /// each corrupted database, as this allows each one to be individually located
  /// and deleted, due to limitations in dependencies. Note that any triggering
  /// of the safety system will also reset the recovery database, meaning
  /// recovery information will be lost.
  ///
  /// [errorHandler] must not (re)throw an error, as this interferes with the
  /// initialisation safety system, and may result in unnecessary data loss.
  ///
  /// Setting [disableInitialisationSafety] `true` will disable the
  /// initialisation safety system, and is not recommended, as this may leave the
  /// application unable to launch if any database becomes corrupted.
  ///
  /// Setting [debugMode] `true` can be useful to diagnose issues, either within
  /// your application or FMTC itself. It enables the Isar inspector and causes
  /// extra console logging in important areas. Prefer to leave disabled to
  /// prevent console pollution and to maximise performance. Whether FMTC chooses
  /// to listen to this value is also dependent on [kDebugMode] - see
  /// [FlutterMapTileCaching.debugMode] for more information.
  /// _Extra logging is currently limited._
  ///
  /// This returns a configured [FlutterMapTileCaching], the same object as
  /// [FlutterMapTileCaching.instance]. Note that [FMTC] is an alias for this
  /// object.
  static Future<FlutterMapTileCaching> initialise({
    String? rootDirectory,
    FMTCSettings? settings,
    void Function(FMTCInitialisationException error)? errorHandler,
    bool disableInitialisationSafety = false,
    bool debugMode = false,
  }) async {
    final directory = await ((rootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(rootDirectory)) >>
            'fmtc')
        .create(recursive: true);

    settings ??= FMTCSettings();

    if (!disableInitialisationSafety) {
      final initialisationSafetyFile =
          directory >>> '.initialisationSafety.tmp';
      final needsRescue = await initialisationSafetyFile.exists();

      await initialisationSafetyFile.create();
      final writeSink =
          initialisationSafetyFile.openWrite(mode: FileMode.writeOnlyAppend);

      await FMTCRegistry.initialise(
        directory: directory,
        databaseMaxSize: settings.databaseMaxSize,
        databaseCompactCondition: settings.databaseCompactCondition,
        errorHandler: errorHandler,
        initialisationSafetyWriteSink: writeSink,
        safeModeSuccessfulIDs:
            needsRescue ? await initialisationSafetyFile.readAsLines() : null,
        debugMode: debugMode && kDebugMode,
      );

      await writeSink.close();
      await initialisationSafetyFile.delete();
    } else {
      await FMTCRegistry.initialise(
        directory: directory,
        databaseMaxSize: settings.databaseMaxSize,
        databaseCompactCondition: settings.databaseCompactCondition,
        errorHandler: errorHandler,
        initialisationSafetyWriteSink: null,
        safeModeSuccessfulIDs: null,
        debugMode: debugMode && kDebugMode,
      );
    }

    return _instance = FMTC._(
      rootDirectory: RootDirectory._(directory),
      settings: settings,
      debugMode: debugMode,
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

  /// Get a [StoreDirectory] by name, without creating it automatically
  ///
  /// Use `.manage.create()` to create it asynchronously. Alternatively, use
  /// `[]` to get a store by name and automatically create it synchronously.
  StoreDirectory call(String storeName) => StoreDirectory._(
        storeName,
        autoCreate: false,
      );

  /// Get a [StoreDirectory] by name, and create it synchronously automatically
  ///
  /// Prefer [call]/`()` wherever possible, as this method blocks the thread.
  /// Note that that method does not automatically create the store.
  StoreDirectory operator [](String storeName) => StoreDirectory._(
        storeName,
        autoCreate: true,
      );
}
