import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../internal/exts.dart';
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
      constructStream(_access.metadata),
      constructStream(_access.stats),
      constructStream(_access.tiles),
    ]);

    return debounce == null ? stream : stream.debounce(debounce);
  }
}
