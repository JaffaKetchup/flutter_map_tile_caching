// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Equivalent to [FMTCRoot], provided to ease migration only
///
/// The name refers to earlier versions of this library where the filesystem
/// was used for storage, instead of a database.
///
/// This deprecation typedef will be removed in a future release: migrate to
/// [FMTCRoot].
@Deprecated(
  '''
Migrate to `FMTCRoot`. This deprecation typedef is provided to ease migration 
only. It will be removed in a future version.
''',
)
typedef RootDirectory = FMTCRoot;

/// Provides access to management, statistics, recovery, migration (and the
/// import functionality) on the intitialised root.
///
/// Note that this does not provide direct access to any [FMTCStore]s.
abstract class FMTCRoot {
  const FMTCRoot._();

  /// Manage the root's representation on the filesystem
  ///
  /// To create, initialise FMTC. Assume that FMTC is ready after initialisation
  /// and before [RootManagement.delete] is called.
  static RootManagement get manage => const RootManagement._();

  /// Get statistics about this root (and all sub-stores)
  static RootStats get stats => const RootStats._();

  /// Manage the download recovery of all sub-stores
  static RootRecovery get recovery => RootRecovery.instance ?? RootRecovery._();

  /// Manage migration for file structure across FMTC versions
  static RootMigrator get migrator => const RootMigrator._();

  /// Provides store import functionality for this root
  ///
  /// The 'fmtc_plus_sharing' module must be installed to add the functionality,
  /// without it, this object provides no functionality.
  static RootImport get import => const RootImport._();
}
