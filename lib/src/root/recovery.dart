import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';

import '../internal/recovery/decode.dart';
import '../internal/recovery/encode.dart';
import '../regions/downloadable_region.dart';
import '../regions/recovered_region.dart';
import '../store/directory.dart';
import 'access.dart';
import 'directory.dart';

/// Manages the download recovery of all sub-stores of this [RootDirectory]
///
/// Is a singleton to ensure a list is kept of the ongoing downloads.
class RootRecovery {
  /// Manages the download recovery of all sub-stores of this [RootDirectory]
  ///
  /// Is a singleton to ensure a list is kept of the ongoing downloads.
  RootRecovery(RootDirectory rootDirectory)
      : _metadata = RootAccess(rootDirectory).metadata {
    instance = this;
  }

  /// Manages the download recovery of all sub-stores of this [RootDirectory]
  ///
  /// Is a singleton to ensure a list is kept of the ongoing downloads.
  static RootRecovery? instance;

  /// Shorthand for [RootAccess.metadata], used commonly throughout
  final Directory _metadata;

  /// Keeps a list of downloads that are ongoing, so they are not recoverable unnecessarily
  final List<int> _downloadsOngoing = [];

  /// Get a list of all recoverable regions
  ///
  /// See [failedRegions] for regions that correspond to failed/stopped downloads.
  Future<List<Future<RecoveredRegion>>> get recoverableRegions => _metadata
      .list()
      .map(
        (e) => e is File && p.extension(e.path, 2) == '.recovery.ini'
            ? decode(e)
            : null,
      )
      .whereType<Future<RecoveredRegion>>()
      .toList();

  /// Get a list of all recoverable regions that correspond to failed/stopped downloads
  ///
  /// See [recoverableRegions] for all regions.
  Future<List<RecoveredRegion>> get failedRegions async =>
      (await Future.wait(await recoverableRegions))
          .where((r) => !_downloadsOngoing.contains(r.id))
          .toList();

  /// Get a specific region, even if it doesn't need recovering
  ///
  /// Returns `Future<null>` if there was no region found
  Future<RecoveredRegion?> getRecoverableRegion(int id) async =>
      (await Future.wait(await recoverableRegions))
          .singleWhereOrNull((r) => r.id == id);

  /// Get a specific region, only if it needs recovering
  ///
  /// Returns `Future<null>` if there was no region found
  Future<RecoveredRegion?> getFailedRegion(int id) async =>
      (await failedRegions).singleWhereOrNull((r) => r.id == id);

  /// Start a recoverable region
  ///
  /// Avoid using externally.
  @internal
  Future<void> start({
    required int id,
    required String description,
    required DownloadableRegion region,
    required StoreDirectory storeDirectory,
  }) async {
    _downloadsOngoing.add(id);
    return encode(
      id: id,
      description: description,
      region: region,
      storeDirectory: storeDirectory,
    );
  }

  /// Safely cancel a recoverable region
  Future<void> cancel(int id) async {
    _downloadsOngoing.remove(id);
    await (await getRecoverableRegion(id))?.file.delete();
  }
}
