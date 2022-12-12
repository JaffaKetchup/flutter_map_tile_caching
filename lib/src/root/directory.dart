// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../fmtc.dart';

/// Represents the root directory and root databases
///
/// Note that this does not provide direct access to any [StoreDirectory]s.
///
/// Reach through [FlutterMapTileCaching.rootDirectory].
@internal
class RootDirectory {
  RootDirectory._(this.directory);

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
  /// Provides access to methods to:
  ///  * Delete and uninitialise
  ///  * Reset
  ///
  /// To create, initialise FMTC. Assume that FMTC is ready after initialisation
  /// and before [RootManagement.delete] is called.
  ///
  /// Whilst the registry database file itself can be modified with methods
  /// included here, it's contents must only be changed by the [FMTCRegistry].
  RootManagement get manage => RootManagement._();

  /// Get statistics about this root (and all sub-stores)
  RootStats get stats => RootStats._();

  /// Manage the download recovery of all sub-stores
  //RootRecovery get recovery => RootRecovery.instance ?? RootRecovery(this);

  /// Manage migration for file structure across FMTC versions
  //RootMigrator get migrator => RootMigrator(this);

  /// Provides store import functionality for this root
  //RootImport get import => RootImport(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RootDirectory && other.directory == directory);

  @override
  int get hashCode => directory.hashCode;
}
