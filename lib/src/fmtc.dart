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

  /// The database or other storage mechanism that FMTC will use as a cache
  /// 'backend'
  ///
  /// Defaults to [ObjectBoxBackend], which uses the ObjectBox library and
  /// database.
  ///
  /// See [FMTCBackend] for more information.
  final FMTCBackend backend;

  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overridden on a case-to-case basis when actually creating the tile
  /// provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Internal constructor, to be used by [initialise]
  const FlutterMapTileCaching._({
    required this.rootDirectory,
    required this.backend,
    required this.defaultTileProviderSettings,
  });

  /// {@macro fmtc.backend.initialise}
  ///
  ///
  /// {@macro fmtc.backend.objectbox.initialise}
  ///
  /// Initialise and prepare FMTC, by creating all necessary directories/files
  /// and configuring the [FlutterMapTileCaching] singleton
  ///
  /// You must construct using this before using [FlutterMapTileCaching.instance],
  /// otherwise a [StateError] will be thrown.
  ///
  /// Returns a configured [FlutterMapTileCaching] instance, and assigns it to
  /// [instance].
  ///
  /// Note that [FMTC] is an alias for [FlutterMapTileCaching].
  ///
  /// ---
  ///
  /// Prefer to leave [rootDirectory] as `null`, which will use
  /// `getApplicationDocumentsDirectory()`. Alternatively, pass a custom
  /// directory - it is recommended to not use a cache directory, as the OS can
  /// clear these without notice at any time.
  ///
  /// Optionally set a custom storage [backend] instead of [ObjectBoxBackend].
  /// Some implementations may accept/require additional arguments that may be
  /// set through [backendImplArgs]. See their documentation for more
  /// information. If provided, they must be of the specified type.
  ///
  /// > The default [ObjectBoxBackend] accepts the following optional
  /// > [backendImplArgs] (note that other implementations may support different
  /// > args). For ease of use, they have been provided in this method as typed
  /// > arguments - these may be useless in other implementations (although they
  /// > will be forwarded to any).
  /// >
  /// > * [macosApplicationGroup] : when creating a sandboxed macOS app,
  /// > use to specify the application group (of less than 20 chars). See
  /// > [the ObjectBox docs](https://docs.objectbox.io/getting-started) for
  /// > details.
  /// > * [maxDatabaseSize] : the maximum size the database file can grow
  /// > to. Exceeding it throws `DbFullException`. Defaults to 10 GB.
  static Future<FlutterMapTileCaching> initialise({
    String? rootDirectory,
    FMTCBackend? backend,
    Map<String, Object> backendImplArgs = const {},
    String? macosApplicationGroup,
    int? maxDatabaseSize,
    FMTCTileProviderSettings? defaultTileProviderSettings,
  }) async {
    final dir = await (rootDirectory == null
            ? await getApplicationDocumentsDirectory()
            : Directory(rootDirectory) >> 'fmtc')
        .create(recursive: true);

    backend ??= ObjectBoxBackend();
    defaultTileProviderSettings ??= FMTCTileProviderSettings();

    // ignore: invalid_use_of_protected_member
    await backend.internal.initialise(
      rootDirectory: dir,
      implSpecificArgs: {
        if (macosApplicationGroup != null)
          'macosApplicationGroup': macosApplicationGroup,
        if (maxDatabaseSize != null) 'maxDatabaseSize': maxDatabaseSize,
      }..addAll(backendImplArgs),
    );

    return _instance = FMTC._(
      rootDirectory: RootDirectory._(dir),
      backend: backend,
      defaultTileProviderSettings: defaultTileProviderSettings,
    );
  }

  /// Get the configured instance of [FlutterMapTileCaching], after
  /// [FlutterMapTileCaching.initialise] has been called, for further actions
  static FlutterMapTileCaching get instance =>
      _instance ??
      (throw StateError(
        '''
Use `FlutterMapTileCaching.initialise()` before getting
`FlutterMapTileCaching.instance` (or a method which requires an instance).
        ''',
      ));
  static FlutterMapTileCaching? _instance;

  /// Construct a [FMTCStore] by name
  ///
  /// {@macro fmtc.fmtcstore.sub.noautocreate}
  ///
  /// Equivalent to constructing the [FMTCStore] directly. This method is
  /// provided for backwards-compatibility.
  FMTCStore call(String storeName) => FMTCStore(storeName);
}
