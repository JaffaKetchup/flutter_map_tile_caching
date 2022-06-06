import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'internal/store/directory.dart';
import 'internal/tile_provider.dart';
import 'root/directory.dart';
import 'root/manage.dart';
import 'settings/tile_provider_settings.dart';

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

  /// Requests for app to be excluded from battery optimizations to aid running a background process
  ///
  /// Only available on Android devices, due to limitations with other operating systems.
  ///
  /// Background downloading is complicated: see the main README for more information.
  ///
  /// If [requestIfDenied] is `true` (default), and the permission has not been granted, an intrusive system dialog will be displayed. If `false`, this method will only check whether it has been granted or not.
  ///
  /// If the dialog does appear it contains is no explanation for the user, except that the app will be allowed to run in the background all the time, so less technical users may be put off. It is up to you to decide (and program accordingly) if you want to show a reason first, then request the permission.
  ///
  /// Will return ([Future]) `true` if permission was granted, `false` if the permission was denied.
  static Future<bool> requestIgnoreBatteryOptimizations(
    BuildContext context, {
    bool requestIfDenied = true,
  }) async {
    if (Platform.isAndroid) {
      final PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.status;
      if ((status.isDenied || status.isLimited) && requestIfDenied) {
        final PermissionStatus statusAfter =
            await Permission.ignoreBatteryOptimizations.request();
        if (statusAfter.isGranted) return true;
        return false;
      } else if (status.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      throw UnsupportedError(
        'The background download feature is only available on Android due to limitations with other operating systems.',
      );
    }
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
/*void main() async {
  FlutterMapTileCaching.initialise(await RootDirectory.normalCache);
  await FMTC.instance['s'].manage.deleteAsync();
  await FMTC.instance.rootDirectory.manage.deleteAsync();
  FMTC.instance.rootDirectory.stats.noCache.rootLength;
  FMTC.instance['s'].getTileProvider();
  await FMTC.instance.rootDirectory.recovery.cancel(0);
}*/
