// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides access to statistics, recovery, migration (and the import
/// functionality) on the intitialised root.
///
/// Management services are not provided here, instead use methods on the
/// backend directly.
///
/// Note that this does not provide direct access to any [FMTCStore]s.
abstract class FMTCRoot {
  const FMTCRoot._();

  /// Get statistics about this root (and all sub-stores)
  static RootStats get stats => const RootStats._();

  /// Manage the download recovery of all sub-stores
  static RootRecovery get recovery => RootRecovery._();

  /// Export & import 'archives' of selected stores and tiles, outside of the
  /// FMTC environment
  static RootExternal external({required String pathToArchive}) =>
      RootExternal._(pathToArchive);
}
