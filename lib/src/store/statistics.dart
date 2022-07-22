import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../internal/exts.dart';
import '../misc/enums.dart';
import 'access.dart';
import 'directory.dart';

/// Provides statistics about a [StoreDirectory]
class StoreStats {
  /// The store directory to provide statistics about
  final StoreDirectory _storeDirectory;

  /// Internally force re-calculation for all statistics, instead of retrieving from cache via [_csgSync] or [_csgAsync]
  final bool _forceRecalculation;

  /// Provides statistics about a [StoreDirectory]
  StoreStats(this._storeDirectory, {bool forceRecalculation = false})
      : _forceRecalculation = forceRecalculation,
        _access = StoreAccess(_storeDirectory);

  /// Shorthand for [StoreDirectory.access], used commonly throughout
  final StoreAccess _access;

  /// Force re-calculation for all statistics instead of retrieving from stats cache
  StoreStats get noCache =>
      StoreStats(_storeDirectory, forceRecalculation: true);

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
  /// [statTypes] dictates the types of statistics to remove, defaulting to only 'length' and 'size'. Set to `null` to remove all types.
  void invalidateCachedStatistics({
    List<String>? statTypes = const [
      'length',
      'size',
    ],
  }) {
    try {
      (statTypes ??
              [
                'length',
                'size',
                'cacheHits',
                'cacheMisses',
              ])
          .map((e) => _access.stats >>> '$e.cache')
          .forEach((e) => e.deleteSync());
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Remove the cached statistics asynchronously
  ///
  /// For synchronous version, see [invalidateCachedStatistics].
  ///
  /// [statTypes] dictates the types of statistics to remove, defaulting to only 'length' and 'size'. Set to `null` to remove all types.
  Future<void> invalidateCachedStatisticsAsync({
    List<String>? statTypes = const [
      'length',
      'size',
    ],
  }) async {
    try {
      await Future.wait(
        (statTypes ??
                [
                  'length',
                  'size',
                  'cacheHits',
                  'cacheMisses',
                ])
            .map((e) => (_access.stats >>> '$e.cache').delete()),
      );
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Retrieve the size of the store in kibibytes (KiB)
  ///
  /// For asynchronous version, see [storeSizeAsync].
  ///
  /// Includes all files beneath the store, not necessarily just tiles.
  double get storeSize => double.parse(
        _csgSync(
          'size',
          () => _access.real
              .listSync(recursive: true)
              .map((e) => e is File ? e.lengthSync() / 1024 : 0)
              .sum,
        ),
      );

  /// Retrieve the size of the store in kibibytes (KiB)
  ///
  /// For asynchronous version, see [storeSize].
  ///
  /// Includes all files beneath the store, not necessarily just tiles.
  Future<double> get storeSizeAsync async => double.parse(
        await _csgAsync(
          'size',
          () async => (await _access.real
                  .list(recursive: true)
                  .asyncMap(
                    (e) async => e is File ? await e.length() / 1024 : 0,
                  )
                  .toList())
              .sum,
        ),
      );

  /// Retrieve the number of stored tiles in a store
  ///
  /// For asynchronous version, see [storeLengthAsync].
  ///
  /// Only includes tiles stored, not necessarily all files.
  int get storeLength => int.parse(
        _csgSync(
          'length',
          () => _access.tiles.listSync().length,
        ),
      );

  /// Retrieve the number of stored tiles in a store
  ///
  /// For synchronous version, see [storeLength].
  ///
  /// Only includes tiles stored, not necessarily all files.
  Future<int> get storeLengthAsync async => int.parse(
        await _csgAsync(
          'length',
          () => _access.tiles.list().length,
        ),
      );

  /// Retrieve the number of tiles that were successfully retrieved from the store during browsing
  ///
  /// For asynchronous version, see [cacheHitsAsync].
  ///
  /// If using [noCache], this will always return 0.
  int get cacheHits => int.parse(
        _csgSync(
          'cacheHits',
          () => 0,
        ),
      );

  /// Retrieve the number of tiles that were successfully retrieved from the store during browsing
  ///
  /// For synchronous version, see [cacheHits].
  ///
  /// If using [noCache], this will always return 0.
  Future<int> get cacheHitsAsync async => int.parse(
        await _csgAsync(
          'cacheHits',
          () => Future.sync(() => 0),
        ),
      );

  /// Retrieve the number of tiles that were unsuccessfully retrieved from the store during browsing
  ///
  /// For asynchronous version, see [cacheMissesAsync].
  ///
  /// If using [noCache], this will always return 0.
  int get cacheMisses => int.parse(
        _csgSync(
          'cacheMisses',
          () => 0,
        ),
      );

  /// Retrieve the number of tiles that were unsuccessfully retrieved from the store during browsing
  ///
  /// For synchronous version, see [cacheMisses].
  Future<int> get cacheMissesAsync async => int.parse(
        await _csgAsync(
          'cacheMisses',
          () => Future.sync(() => 0),
        ),
      );

  /// Watch for changes in the current store
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
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

    final Stream<void> stream = constructStream(_access.real).mergeAll([
      if (storeParts.contains(StoreParts.metadata))
        constructStream(_access.metadata),
      if (storeParts.contains(StoreParts.stats)) constructStream(_access.stats),
      if (storeParts.contains(StoreParts.tiles)) constructStream(_access.tiles),
    ]);

    return debounce == null ? stream : stream.debounce(debounce);
  }
}
