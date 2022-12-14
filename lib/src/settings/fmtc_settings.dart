// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';

import '../providers/tile_provider.dart';
import 'tile_provider_settings.dart';

/// Global 'flutter_map_tile_caching' settings
class FMTCSettings {
  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overridden on a case-to-case basis when actually creating the tile provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Sets a strict upper limit on every database file (defaults to 1GiB)
  ///
  /// Prefer to set a limit on the number of tiles instead, using
  /// [FMTCTileProviderSettings.maxStoreLength].
  ///
  /// Note that there is more than one database file, and this value applies
  /// independently to each of them.
  ///
  /// Setting this value too low may cause errors. Setting this value too high
  /// and not limiting the number of tiles may result in slower operations and
  /// a negative user experience: a large, unknown file may be deleted by a user,
  /// causing significant data loss.
  final int databaseMaxSize;

  /// Create custom global 'flutter_map_tile_caching' settings
  FMTCSettings({
    FMTCTileProviderSettings? defaultTileProviderSettings,
    this.databaseMaxSize = Isar.defaultMaxSizeMiB,
  }) : defaultTileProviderSettings =
            defaultTileProviderSettings ?? FMTCTileProviderSettings();
}
