import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../internal/exts.dart';
import '../internal/store/directory.dart';
import 'access.dart';
import 'manage.dart';
import 'recovery.dart';
import 'statistics.dart';

/// Access point to a root
///
/// Contains access to:
/// * Statistics
/// * Management
/// * Low-Level Access (advanced)
///
/// Does not provide direct access to any [StoreDirectory]s.
///
/// A root is identified by it's representation on the filesystem (directory). A root contains multiple sub-directories, and sub-[StoreDirectory]s.
class RootDirectory {
  /// The real directory beneath which 'flutter_map_tile_caching' places all data - usually located itself within the application's directories
  final Directory rootDirectory;

  /// Create a [RootDirectory] set based on your own custom directory
  ///
  /// This should only be used under special circumstances. Ensure that your application has full access to the directory, or permission errors will occur. You should ensure that the path is suitable for storing only FMTC related data.
  ///
  /// Construction via this method automatically calls [RootManagement.create] before returning (by default), so the caching directories will exist unless deleted using [RootManagement.delete]. Disable this initialisation by setting [autoCreate] to `false`.
  RootDirectory.custom(
    this.rootDirectory, {
    bool autoCreate = true,
  }) {
    if (autoCreate) manage.create();
  }

  /// Create a [RootDirectory] set based on the app's documents directory
  ///
  /// This is the recommended base, as the directory cannot be cleared by the OS without warning. To completely clear this directory, the user must manually clear ALL app data, not just app cache.
  ///
  /// Construction via this method automatically calls [RootManagement.createAsync] before returning, so the caching directories will exist unless deleted using [RootManagement.delete].
  static Future<RootDirectory> get normalCache async {
    final RootDirectory returnable = RootDirectory.custom(
      (await getApplicationDocumentsDirectory()) >> 'fmtc',
      autoCreate: false,
    );
    await returnable.manage.createAsync();
    return returnable;
  }

  /// Create a [RootDirectory] set based on the app's temporary directory
  ///
  /// This should only be used when requested by a user, as the directory can be cleared by the OS without warning.
  ///
  /// Construction via this method automatically calls [RootManagement.createAsync] before returning, so the caching directories will exist unless deleted using [RootManagement.delete].
  static Future<RootDirectory> get temporaryCache async {
    final RootDirectory returnable = RootDirectory.custom(
      (await getTemporaryDirectory()) >> 'fmtc',
      autoCreate: false,
    );
    await returnable.manage.createAsync();
    return returnable;
  }

  /// Check whether all directories exist synchronously
  ///
  /// Does not check any sub-stores.
  bool get ready => [
        access.stores.existsSync(),
        access.stats.existsSync(),
        access.metadata.existsSync(),
      ].every((e) => e);

  /// Check whether all directories exist asynchronously
  ///
  /// Does not check any sub-stores.
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        access.stores.exists(),
        access.stats.exists(),
        access.metadata.exists(),
      ]))
          .every((e) => e);

  /// Get direct filesystem access paths
  ///
  /// This should only be used in special cases, when modifying the root manually for example.
  RootAccess get access => RootAccess(this);

  /// Manage the root's representation on the filesystem
  ///
  /// Provides access to methods to:
  ///  * Create
  ///  * Delete
  ///  * Reset
  RootManagement get manage => RootManagement(this);

  /// Get statistics about this root (and all sub-stores)
  RootStats get stats => RootStats(this);

  /// Manage the download recovery of all sub-stores
  RootRecovery get recovery => RootRecovery.instance ?? RootRecovery(this);

  @override
  String toString() => 'RootDirectory(_rootDirectory: $rootDirectory)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RootDirectory && other.rootDirectory == rootDirectory;
  }

  @override
  int get hashCode => rootDirectory.hashCode;

  RootDirectory copyWith({
    Directory? rootDirectory,
    bool autoCreate = true,
  }) =>
      RootDirectory.custom(
        rootDirectory ?? this.rootDirectory,
        autoCreate: autoCreate,
      );
}
