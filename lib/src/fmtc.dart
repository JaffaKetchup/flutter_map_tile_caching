// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stream_transform/stream_transform.dart';

import 'db/defs/store.dart';
import 'db/defs/tile.dart';
import 'db/registry.dart';
import 'db/tools.dart';
import 'internal/exts.dart';
import 'internal/tile_provider.dart';
import 'misc/enums.dart';
import 'settings/fmtc_settings.dart';
import 'settings/tile_provider_settings.dart';

part 'root/directory.dart';
part 'root/manage.dart';
part 'root/statistics.dart';
part 'store/directory.dart';
part 'store/manage.dart';
part 'store/statistics.dart';

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
    FMTCSettings? settings,
  }) async {
    final directory = await ((customRootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(customRootDirectory)) >>
            'fmtc')
        .create(recursive: true);

    final registry = await FMTCRegistry.initialise(dirReal: directory);

    // TODO: REMOVE FOR PRODUCTION
    await registry.registryDatabase.writeTxn(() async {
      await registry.registryDatabase.clear();
      await registry.registryDatabase.stores
          .put(DbStore(name: 'OpenStreetMap'));
      await registry.registryDatabase.stores
          .put(DbStore(name: 'OpenStreetMap'));
      await registry.registryDatabase.stores
          .put(DbStore(name: r'assssssssssssssss\'));
    });
    await registry.synchronise();

    return _instance = FMTC._(
      rootDirectory: RootDirectory._(directory),
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

  /// Get a [StoreDirectory] representation by store name, without creating it
  StoreDirectory call(String storeName) => StoreDirectory._(storeName);
}
