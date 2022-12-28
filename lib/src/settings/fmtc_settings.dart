// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Global FMTC settings, used throughout or in long lasting places
class FMTCSettings {
  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overridden on a case-to-case basis when actually creating the tile provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Sets a strict upper size limit on each underlying database individually
  /// (of which there are multiple)
  ///
  /// Prefer to set a limit on the number of tiles instead, using
  /// [FMTCTileProviderSettings.maxStoreLength].
  ///
  /// Setting this value too low may cause errors. Setting this value too high
  /// and not limiting the number of tiles may result in slower operations and
  /// a negative user experience: a large, unknown file may be deleted by a user,
  /// causing significant data loss.
  ///
  /// Defaults to 1GiB (1024MiB).
  final int databaseMaxSize;

  /// Sets conditions that will trigger each underlying database (individually)
  /// to compact/shrink
  ///
  /// Isar databases can contain unused space that will be reused for later
  /// operations and storage. This operation can be expensive, as the entire
  /// database must be copied. Ensure your chosen conditions do not trigger
  /// compaction too often.
  ///
  /// Defaults to triggering compaction when the size of the database file can
  /// be halved.
  ///
  /// Set to `null` to never automatically compact (not recommended). Note that
  /// exporting a store will always compact it's underlying database.
  final DatabaseCompactCondition? databaseCompactCondition;

  /// Create custom global FMTC settings, used throughout or in long lasting
  /// places
  FMTCSettings({
    FMTCTileProviderSettings? defaultTileProviderSettings,
    this.databaseMaxSize = Isar.defaultMaxSizeMiB,
    this.databaseCompactCondition = const CompactCondition(minRatio: 2),
  }) : defaultTileProviderSettings =
            defaultTileProviderSettings ?? FMTCTileProviderSettings();
}
