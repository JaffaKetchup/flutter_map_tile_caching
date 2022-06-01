import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';

import '../internal/exts.dart';
import '../internal/store/directory.dart';
import 'access.dart';
import 'directory.dart';

/// Provides statistics about a [RootDirectory]
class RootStats {
  /// The root directory to provide statistics about
  final RootDirectory _rootDirectory;

  /// Internally force re-calculation for all statistics, instead of retrieving from cache via [_csgSync] or [_csgAsync]
  final bool _forceRecalculation;

  /// Provides statistics about a [RootDirectory]
  RootStats(this._rootDirectory, {bool forceRecalculation = false})
      : _forceRecalculation = forceRecalculation,
        _access = RootAccess(_rootDirectory);

  /// Shorthand for [RootDirectory.access], used commonly throughout
  final RootAccess _access;

  /// Force re-calculation for all statistics instead of retrieving from stats cache
  RootStats get noCache => RootStats(_rootDirectory, forceRecalculation: true);

  /// Get a cached statistic or fallback to a calculation synchronously
  ///
  /// Stands for 'CachedStatisticGetterSynchronous'
  String _csgSync(String statType, dynamic Function() calculation) {
    final File f = _access.stats >>> '$statType.cache';

    if (!_forceRecalculation && f.existsSync()) {
      return f.readAsStringSync();
    } else {
      final String calculated = calculation().toString();
      f.writeAsStringSync(calculated, flush: true);
      return calculated;
    }
  }

  /// Get a cached statistic or fallback to a calculation asynchronously
  ///
  /// Stands for 'CachedStatisticGetterAsynchronous'
  Future<String> _csgAsync(
    String statType,
    Future<dynamic> Function() calculation,
  ) async {
    final File f = _access.stats >>> '$statType.cache';

    if (!_forceRecalculation && await f.exists()) {
      return f.readAsString();
    } else {
      final String calculated = (await calculation()).toString();
      await f.writeAsString(calculated, flush: true);
      return calculated;
    }
  }

  /// Remove the cached statistics
  ///
  /// If [statType] is `null`, all statistic caches are deleted, otherwise only the specified cache is deleted.
  Future<void> invalidateCachedStatistics(String? statType) async {
    if (statType != null) {
      await (_access.stats >>> '$statType.cache').delete();
    } else {
      await (_access.stats >>> 'length.cache').delete();
      await (_access.stats >>> 'size.cache').delete();
    }
  }

  /// Retrieve all the available [StoreDirectory]s
  ///
  /// For asynchronous version, see [storesAvailableAsync]. Note that this statstic is not cached for performance, as the effect would be negligible.
  List<StoreDirectory> get storesAvailable => _access.stores
      .listSync()
      .map(
        (e) => e is Directory
            ? StoreDirectory(_rootDirectory, p.split(e.absolute.path).last)
            : null,
      )
      .whereType<StoreDirectory>()
      .toList();

  /// Retrieve all the available [StoreDirectory]s
  ///
  /// For synchronous version, see [storesAvailable]. Note that this statstic is not cached for performance, as the effect would be negligible.
  Future<List<StoreDirectory>> get storesAvailableAsync async =>
      (await _access.stores
              .list()
              .map(
                (e) => e is Directory
                    ? StoreDirectory(
                        _rootDirectory,
                        p.split(e.absolute.path).last,
                      )
                    : null,
              )
              .toList())
          .whereType<StoreDirectory>()
          .toList();

  /// Retrieve the size of the root in kibibytes (KiB)
  ///
  /// For asynchronous version, see [rootSizeAsync].
  ///
  /// Technically just sums up the size of all sub-stores, thus ignoring any cached root statistics, etc.
  ///
  /// Includes all files in all stores, not necessarily just tiles.
  double get rootSize => double.parse(
        _csgSync(
          'size',
          () => storesAvailable.map((e) => e.stats.storeSize).sum,
        ),
      );

  /// Retrieve the size of the root in kibibytes (KiB)
  ///
  /// For synchronous version, see [rootSize].
  ///
  /// Technically just sums up the size of all sub-stores, thus ignoring any cached root statistics, etc.
  ///
  /// Includes all files in all stores, not necessarily just tiles.
  Future<double> get rootSizeAsync async => double.parse(
        await _csgAsync(
          'size',
          () async => (await Future.wait(
            (await storesAvailableAsync).map((e) => e.stats.storeSizeAsync),
          ))
              .sum,
        ),
      );

  /// Retrieve the number of stored tiles in all sub-stores
  ///
  /// For asynchronous version, see [rootLengthAsync].
  ///
  /// Only includes tiles stored, not necessarily all files.
  int get rootLength => int.parse(
        _csgSync(
          'length',
          () => storesAvailable.map((e) => e.stats.storeLength).sum,
        ),
      );

  /// Retrieve the number of stored tiles in all sub-stores
  ///
  /// For synchronous version, see [rootLength].
  ///
  /// Only includes tiles stored, not necessarily all files.
  Future<int> get rootLengthAsync async => int.parse(
        await _csgAsync(
          'length',
          () async => (await Future.wait(
            (await storesAvailableAsync).map((e) => e.stats.storeLengthAsync),
          ))
              .sum,
        ),
      );

  /// Watch for changes in the current cache
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// By default, [recursive] is set to `false`, meaning only top level changes (those to do with each store) will be caught. Enable recursivity to also include events from all sub-directories.
  ///
  /// Only supported on some platforms. Will throw [UnsupportedError] if platform has no internal support (eg. OS X 10.6 and below). Note that recursive watching is not supported on some other platforms, but handling for this is unspecified.
  ///
  /// Control which changes are caught through the [fileSystemEvents] property, which takes [FileSystemEvent]s.
  ///
  /// Enable debouncing to prevent unnecessary events for small changes in detail using [debounce]. Defaults to 200ms, or set to null to disable debouncing.
  ///
  /// Debouncing example (dash roughly represents [debounce]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  Stream<void> watchChanges({
    bool recursive = false,
    Duration? debounce = const Duration(milliseconds: 200),
    int fileSystemEvents = FileSystemEvent.all,
  }) {
    if (!FileSystemEntity.isWatchSupported) {
      throw UnsupportedError(
        'Watching is not supported on the current platform',
      );
    }

    final stream = _access.real
        .watch(events: fileSystemEvents)
        .map((e) => null)
        .mergeAll(
          !recursive
              ? []
              : storesAvailable.map(
                  (e) =>
                      e.stats.watchChanges(debounce: debounce).map((e) => null),
                ),
        )
        .mergeAll([
      _access.metadata.watch(events: fileSystemEvents).map((e) => null),
      _access.stats.watch(events: fileSystemEvents).map((e) => null),
      _access.stores.watch(events: fileSystemEvents).map((e) => null)
    ]);

    return debounce == null ? stream : stream.debounce(debounce);
  }
}
