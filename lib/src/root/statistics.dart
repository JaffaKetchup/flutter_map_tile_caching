// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../internal/exts.dart';
import '../misc/enums.dart';
import '../store/directory.dart';
import '../store/statistics.dart';
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

  /// Remove the cached statistics synchronously
  ///
  /// For asynchronous version, see [invalidateCachedStatisticsAsync].
  ///
  /// If [statType] is `null`, all statistic caches are deleted, otherwise only the specified cache is deleted.
  void invalidateCachedStatistics(String? statType) {
    try {
      if (statType != null) {
        (_access.stats >>> '$statType.cache').deleteSync();
      } else {
        (_access.stats >>> 'length.cache').deleteSync();
        (_access.stats >>> 'size.cache').deleteSync();
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Remove the cached statistics asynchronously
  ///
  /// For synchronous version, see [invalidateCachedStatistics].
  ///
  /// If [statType] is `null`, all statistic caches are deleted, otherwise only the specified cache is deleted.
  Future<void> invalidateCachedStatisticsAsync(String? statType) async {
    try {
      if (statType != null) {
        await (_access.stats >>> '$statType.cache').delete();
      } else {
        await Future.wait([
          (_access.stats >>> 'length.cache').delete(),
          (_access.stats >>> 'size.cache').delete(),
        ]);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Retrieve all the available [StoreDirectory]s
  ///
  /// For asynchronous version, see [storesAvailableAsync]. Note that this statistic is not cached for performance, as the effect would be negligible.
  List<StoreDirectory> get storesAvailable => _access.stores
      .listSync()
      .map(
        (e) => e is Directory
            ? StoreDirectory(
                _rootDirectory,
                p.split(e.absolute.path).last,
                autoCreate: false,
              )
            : null,
      )
      .whereType<StoreDirectory>()
      .toList();

  /// Retrieve all the available [StoreDirectory]s
  ///
  /// For synchronous version, see [storesAvailable]. Note that this statistic is not cached for performance, as the effect would be negligible.
  Future<List<StoreDirectory>> get storesAvailableAsync async =>
      (await (await _access.stores.listWithExists())
              .map(
                (e) => e is Directory
                    ? StoreDirectory(
                        _rootDirectory,
                        p.split(e.absolute.path).last,
                        autoCreate: false,
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
  double get rootSize =>
      double.tryParse(
        _csgSync(
          'size',
          () => storesAvailable.map((e) => e.stats.storeSize).sum,
        ),
      ) ??
      0;

  /// Retrieve the size of the root in kibibytes (KiB)
  ///
  /// For synchronous version, see [rootSize].
  ///
  /// Technically just sums up the size of all sub-stores, thus ignoring any cached root statistics, etc.
  ///
  /// Includes all files in all stores, not necessarily just tiles.
  Future<double> get rootSizeAsync async =>
      double.tryParse(
        await _csgAsync(
          'size',
          () async => (await Future.wait(
            (await storesAvailableAsync).map((e) => e.stats.storeSizeAsync),
          ))
              .sum,
        ),
      ) ??
      0;

  /// Retrieve the number of stored tiles in all sub-stores
  ///
  /// For asynchronous version, see [rootLengthAsync].
  ///
  /// Only includes tiles stored, not necessarily all files.
  int get rootLength =>
      int.tryParse(
        _csgSync(
          'length',
          () => storesAvailable.map((e) => e.stats.storeLength).sum,
        ),
      ) ??
      0;

  /// Retrieve the number of stored tiles in all sub-stores
  ///
  /// For synchronous version, see [rootLength].
  ///
  /// Only includes tiles stored, not necessarily all files.
  Future<int> get rootLengthAsync async =>
      int.tryParse(
        await _csgAsync(
          'length',
          () async => (await Future.wait(
            (await storesAvailableAsync).map((e) => e.stats.storeLengthAsync),
          ))
              .sum,
        ),
      ) ??
      0;

  /// Watch for changes in the current cache
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Recursively watch specific sub-stores (using [StoreStats.watchChanges]) by providing them as a list of [StoreDirectory]s to [recursive]. To watch all stores, use the [storesAvailable]/[storesAvailableAsync] getter as the argument.  By default, no sub-stores are watched (empty list), meaning only top level changes (those to do with each store) will be caught.
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
    List<StoreDirectory> recursive = const [],
    List<ChangeType> events = const [
      ChangeType.ADD,
      ChangeType.MODIFY,
      ChangeType.REMOVE,
    ],
    List<RootParts> rootParts = RootParts.values,
    List<StoreParts> storeParts = StoreParts.values,
  }) {
    Stream<void> constructStream(Directory dir) => FileSystemEntity
            .isWatchSupported
        ? dir
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
        : DirectoryWatcher(dir.absolute.path)
            .events
            .where((evt) => events.contains(evt.type))
            .map<void>((e) {});

    final Stream<void> stream = constructStream(_access.real)
        .mergeAll(
      recursive.map(
        (e) => e.stats.watchChanges(
          debounce: debounce,
          events: events,
          storeParts: storeParts,
        ),
      ),
    )
        .mergeAll([
      if (rootParts.contains(RootParts.recovery))
        constructStream(_access.recovery),
      if (rootParts.contains(RootParts.stats)) constructStream(_access.stats),
      if (rootParts.contains(RootParts.stores)) constructStream(_access.stores),
    ]);

    return debounce == null ? stream : stream.debounce(debounce);
  }
}
