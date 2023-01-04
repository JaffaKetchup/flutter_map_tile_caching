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
  /// This returns a configured [FlutterMapTileCaching], the same object as
  /// [FlutterMapTileCaching.instance]. Note that [FMTC] is an alias for this
  /// object.
  static Future<FlutterMapTileCaching> initialise({
    String? customRootDirectory,
    FMTCSettings? customSettings,
    void Function(FMTCInitialisationException error)? errorHandler,
    bool disableInitialisationSafety = false,
  }) async {
    final directory = await ((customRootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(customRootDirectory)) >>
            'fmtc')
        .create(recursive: true);
    final settings = customSettings ?? FMTCSettings();

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
      );

      await writeSink.close();
      await initialisationSafetyFile.delete();
    } else {
      await FMTCRegistry.initialise(
        directory: directory,
        databaseMaxSize: settings.databaseMaxSize,
        databaseCompactCondition: settings.databaseCompactCondition,
        errorHandler: errorHandler,
      );
    }

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

/// An exception raised when FMTC failed to initialise
///
/// May indicate a previously fatal crash due to a corrupted database. If this is
/// the case, [source] will be `null`, [wasFatal] will be `true`, and the
/// corrupted database will be deleted.
class FMTCInitialisationException implements Exception {
  /// The original error object
  ///
  /// If `null` indicates a previously fatal crash due to a corrupted database. If
  /// this is the case, [wasFatal] will be `true`, and the corrupted database will
  /// be deleted.
  final Object? source;

  /// Indicates whether there was a previously fatal crash due to a corrupted
  /// database. If this is the case, [source] will be `null`, and the corrupted
  /// database will be deleted.
  final bool wasFatal;

  /// Create an exception raised when FMTC failed to initialise
  ///
  /// May indicate a previously fatal crash. If this is the case, [source] will
  /// be `null`, [wasFatal] will be `true`, and the corrupted database will be
  /// deleted.
  @internal
  FMTCInitialisationException({
    required this.source,
  }) : wasFatal = source == null;

  /// Converts the [source] into a string
  @override
  String toString() => source.toString();
}
