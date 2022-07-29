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
/// Is a singleton to ensure functioning as expected.
class RootRecovery {
  /// The root directory containing the stores to recover from
  final RootDirectory _rootDirectory;

  /// Manages the download recovery of all sub-stores of this [RootDirectory]
  ///
  /// Is a singleton to ensure functioning as expected.
  RootRecovery(this._rootDirectory)
      : _metadata = RootAccess(_rootDirectory).recovery {
    instance = this;
  }

  /// Manages the download recovery of all sub-stores of this [RootDirectory]
  ///
  /// Is a singleton to ensure functioning as expected.
  static RootRecovery? instance;

  /// Shorthand for [RootAccess.recovery], used commonly throughout
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
    required String storeName,
    required DownloadableRegion region,
    required StoreDirectory storeDirectory,
  }) async {
    _downloadsOngoing.add(id);
    return encode(
      id: id,
      storeName: storeName,
      region: region,
      rootDirectory: _rootDirectory,
    );
  }

  /// Safely cancel a recoverable region
  Future<void> cancel(int id) async {
    _downloadsOngoing.remove(id);
    await (await getRecoverableRegion(id))?.file.delete();
  }

  /*/// Watch for changes in recovery information
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder].
  ///
  /// Control which changes are caught through the [events] parameter, which takes a list of [ChangeType]s. Catches all change types by default.
  ///
  /// Enable debouncing to prevent unnecessary events for small changes in detail using [debounce]. Defaults to 200ms, or set to null to disable debouncing.
  ///
  /// Debouncing example (dash roughly represents [debounce]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  Stream<void> watchChanges({
    Duration? debounce = const Duration(milliseconds: 200),
    List<ChangeType> events = const [
      ChangeType.ADD,
      ChangeType.MODIFY,
      ChangeType.REMOVE
    ],
  }) {
    final Stream<void> stream = FileSystemEntity.isWatchSupported
        ? _metadata
            .watch(
              events: [
                events.contains(ChangeType.ADD) ? FileSystemEvent.create : null,
                events.contains(ChangeType.MODIFY)
                    ? FileSystemEvent.modify
                    : null,
                events.contains(ChangeType.MODIFY)
                    ? FileSystemEvent.move
                    : null,
                events.contains(ChangeType.REMOVE)
                    ? FileSystemEvent.delete
                    : null,
              ].whereType<int>().reduce((v, e) => v | e),
            )
            .map<void>((e) {})
        : DirectoryWatcher(_metadata.absolute.path)
            .events
            .where((evt) => events.contains(evt.type))
            .map<void>((e) {});

    return debounce == null ? stream : stream.debounce(debounce);
  }*/
}
