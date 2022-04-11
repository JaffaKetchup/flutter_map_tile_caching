import 'internal/store.dart';
import 'structure/root.dart';

/// Direct alias for easier development
///
/// Prefer use of full [FlutterMapTileCaching] when initialising to ensure readability.
typedef FMTC = FlutterMapTileCaching;

/// Keys for global 'flutter_map_tile_caching' settings
///
/// Each key has an [Object] assigned, such as a [bool] or [String].
enum FMTCSettings {
  /// Whether to apply compression to tile stores when not in use (alpha - use with caution)
  ///
  /// Value/Default: [bool]/`false`
  compression,

  /// Whether to also cache statistics
  ///
  /// Value/Default: [bool]/`true`
  advancedCaching,
}

/// Main singleton access point for 'flutter_map_tile_caching'
///
/// You must construct using [FlutterMapTileCaching.initialise] before using [FlutterMapTileCaching.instance], otherwise a [StateError] will be thrown. Note that the singleton can be re-initialised/changed by calling the aforementioned constructor again.
///
/// [FMTC] is an alias for this object.
class FlutterMapTileCaching {
  /// The cache's root
  ///
  /// Recommended setup is `await RootDirectory.normalCache`, but any [RootDirectory] is accepted. [FlutterMapTileCaching] checks that [RootDirectory.ready] is 'true', otherwise a [StateError] is thrown.
  late final RootDirectory rootDirectory;

  /// Change global 'flutter_map_tile_caching' settings
  ///
  /// Use [FMTCSettings] as keys, and override keys with their respective [Object] - see documentation on each key.
  ///
  /// Default is [settingsDefault].
  final Map<FMTCSettings, Object> settings;

  /// Initialise the main singleton access point for 'flutter_map_tile_caching'
  ///
  /// You must construct using this before using [FlutterMapTileCaching.instance], otherwise a [StateError] will be thrown. Note that the singleton can be re-initialised/changed by calling this constructor again.
  ///
  /// This returns the same object as [FlutterMapTileCaching.instance] will afterward. [FMTC] is an alias for this object.
  FlutterMapTileCaching.initialise(
    RootDirectory rootDir, {
    this.settings = settingsDefault,
  }) {
    if (!rootDir.ready) {
      throw StateError(
        'Ensure supplied root directory exists. Try constructing it again.',
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

  /// The default global 'flutter_map_tile_caching' settings, used in [settings]
  static const Map<FMTCSettings, Object> settingsDefault = {
    FMTCSettings.compression: false,
    FMTCSettings.advancedCaching: true,
  };

  /// Get a [StoreDirectory] by store name
  StoreDirectory operator [](String storeName) =>
      StoreDirectory(rootDirectory, storeName);
}

void main() async {
  FlutterMapTileCaching.initialise(
    await RootDirectory.normalCache,
    settings: {
      FMTCSettings.advancedCaching: false,
    },
  );
  FMTC.instance['s'];
}
