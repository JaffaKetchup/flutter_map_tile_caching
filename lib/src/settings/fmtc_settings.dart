// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Global FMTC settings
class FMTCSettings {
  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overridden on a case-to-case basis when actually creating the tile
  /// provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Sets a strict upper size limit on each underlying database individually
  /// (of which there are multiple)
  ///
  /// It is also recommended to set a limit on the number of tiles instead, using
  /// [FMTCTileProviderSettings.maxStoreLength]. If using a generous number
  /// there, use a larger number here as well.
  ///
  /// Setting this value too low may cause unexpected errors when writing to the
  /// database. Setting this value too high may cause memory issues on certain
  /// older devices or emulators.
  ///
  /// Defaults to 2GiB (2048MiB).
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

  /// Create custom global FMTC settings
  FMTCSettings({
    FMTCTileProviderSettings? defaultTileProviderSettings,
    this.databaseMaxSize = 2048,
    this.databaseCompactCondition = const CompactCondition(minRatio: 2),
  }) : defaultTileProviderSettings =
            defaultTileProviderSettings ?? FMTCTileProviderSettings();
}
