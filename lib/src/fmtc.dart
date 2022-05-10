import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/src/internal/tile_provider.dart';
import 'package:latlong2/latlong.dart';

import 'regions/rectangle.dart';
import 'root/directory.dart';
import 'internal/store/directory.dart';

/// Direct alias of [FlutterMapTileCaching] for easier development
///
/// Prefer use of full 'FlutterMapTileCaching' when initialising to ensure readability and understanding in other code.
typedef FMTC = FlutterMapTileCaching;

/// Global 'flutter_map_tile_caching' settings
class FMTCSettings {
  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overriden on a case-to-case basis when actually creating the tile provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Create custom global 'flutter_map_tile_caching' settings
  FMTCSettings({FMTCTileProviderSettings? defaultTileProviderSettings})
      : defaultTileProviderSettings =
            defaultTileProviderSettings ?? FMTCTileProviderSettings();
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
    if (!rootDir.ready) {
      throw StateError(
        'Ensure supplied root directory exists. Try constructing it again, or using `rootDirectory.manage.create()`.',
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
  StoreDirectory operator [](String storeName) =>
      StoreDirectory(rootDirectory, storeName);
}

void main() async {
  FlutterMapTileCaching.initialise(await RootDirectory.normalCache);
  FMTC.instance['s'].manage.deleteAsync();
  FMTC.instance.rootDirectory.manage.deleteAsync();
  FMTC.instance.rootDirectory.stats.noCache.rootLength;
  FMTC.instance['s'].getTileProvider();
}
