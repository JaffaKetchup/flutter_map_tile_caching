// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../db/defs/store.dart';
import '../db/defs/tile.dart';
import '../db/misc/hash.dart';
import '../fmtc.dart';
import '../internal/exts.dart';
import '../store/directory.dart';
import 'migrator.dart';

part 'access.dart';
part 'manage.dart';

/// Represents the root directory and root databases
///
/// Note that this does not provide direct access to any [StoreDirectory]s.
///
/// The [rootDirectory] is the real [Directory] stored on the device, but this
/// object also manages the other required root databases, including the store
/// registry.
class RootDirectory {
  /// The real directory beneath which 'flutter_map_tile_caching' places all
  /// data - usually located itself within the application's directories
  final Directory rootDirectory;

  /// Create a [RootDirectory] set based on your own custom directory
  ///
  /// This should only be used under special circumstances. Ensure that your
  /// application has full access to the directory, or permission errors will
  /// occur. You should ensure that the path is suitable for storing only FMTC
  /// related data.
  RootDirectory.custom(this.rootDirectory);

  /// Create a [RootDirectory] set based on the app's documents directory
  ///
  /// This is the recommended base, as the directory cannot be cleared by the OS
  /// without warning. To completely clear this directory, the user must manually
  /// clear ALL app data, not just app cache.
  static Future<RootDirectory> get normalCache async => RootDirectory.custom(
        (await getApplicationDocumentsDirectory()) >> 'fmtc',
      );

  /// Create a [RootDirectory] set based on the app's temporary directory
  ///
  /// This should only be used when requested by a user, as the directory can be
  /// cleared by the OS without warning.
  static Future<RootDirectory> get temporaryCache async => RootDirectory.custom(
        (await getTemporaryDirectory()) >> 'fmtc',
      );

  _RootAccess get _access => _RootAccess();

  /// Manage the root's representation on the filesystem
  ///
  /// Provides access to methods to:
  ///  * Create
  ///  * Delete
  ///  * Reset
  RootManagement get manage => RootManagement();

  /// Get statistics about this root (and all sub-stores)
  //RootStats get stats => RootStats(this);

  /// Manage the download recovery of all sub-stores
  //RootRecovery get recovery => RootRecovery.instance ?? RootRecovery(this);

  /// Manage migration for file structure across FMTC versions
  RootMigrator get migrator => RootMigrator(this);

  /// Provides store import functionality for this root
  //RootImport get import => RootImport(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RootDirectory && other.rootDirectory == rootDirectory);

  @override
  int get hashCode => rootDirectory.hashCode;
}
