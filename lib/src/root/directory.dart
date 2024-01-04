// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Represents the root directory and root databases
///
/// Note that this does not provide direct access to any [FMTCStore]s.
///
/// The name originates from previous versions of this library, where it
/// represented a real directory instead of a database.
///
/// Reach through [FlutterMapTileCaching.rootDirectory].
class RootDirectory {
  const RootDirectory._(this.directory);

  /// The real directory beneath which FMTC places all data - usually located
  /// within the application's directories
  ///
  /// Provides low level access. Use with caution, and prefer built-in methods!
  /// Corrupting some databases, for example the registry, can lead to data
  /// loss from multiple stores.
  @internal
  @protected
  final Directory directory;

  /// Manage the root's representation on the filesystem
  ///
  /// To create, initialise FMTC. Assume that FMTC is ready after initialisation
  /// and before [RootManagement.delete] is called.
  RootManagement get manage => const RootManagement._();

  /// Get statistics about this root (and all sub-stores)
  RootStats get stats => const RootStats._();

  /// Manage the download recovery of all sub-stores
  RootRecovery get recovery => RootRecovery.instance ?? RootRecovery._();

  /// Manage migration for file structure across FMTC versions
  RootMigrator get migrator => const RootMigrator._();

  /// Provides store import functionality for this root
  ///
  /// The 'fmtc_plus_sharing' module must be installed to add the functionality,
  /// without it, this object provides no functionality.
  RootImport get import => const RootImport._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RootDirectory && other.directory == directory);

  @override
  int get hashCode => directory.hashCode;
}
