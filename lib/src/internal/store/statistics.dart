import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:stream_transform/stream_transform.dart';

import '../exts.dart';
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

  /// Retrieves a (potentially random) tile from the store and uses it to create a cover [Image]
  ///
  /// [random] controls whether the chosen tile is chosen at random or whether the chosen tile is the 'first' tile in the store. Note that 'first' means alphabetically, not chronologically.
  ///
  /// Using random mode may take a while to generate if the random number is large.
  ///
  /// If using random mode, optionally set [maxRange] to an integer (1 <= [maxRange] <= [storeLength]) to only generate a random number between 0 and the specified number. Useful to reduce waiting times or enforce consistency.
  ///
  /// Returns `null` if there are no cached tiles.
  Image? coverImage({
    required bool random,
    int? maxRange,
    double? size,
  }) {
    final int storeLen = storeLength;
    if (storeLen == 0) return null;

    if (!random && maxRange != null) {
      throw ArgumentError(
        'If not in random mode, `maxRange` must be left as `null`',
      );
    }
    if (maxRange != null && (maxRange < 1 || maxRange > storeLen)) {
      throw ArgumentError(
        'If specified, `maxRange` must be more than or equal to 1 and less than or equal to `storeLength`',
      );
    }

    final int? randInt = !random ? null : Random().nextInt(maxRange!);
    int i = 0;

    for (final FileSystemEntity e in _access.tiles.listSync()) {
      if (i >= (randInt ?? 0)) {
        return Image.file(
          File(e.absolute.path),
          width: size,
          height: size,
        );
      }
      i++;
    }

    throw FallThroughError();
  }

  /// Retrieves a (potentially random) tile from the store and uses it to create a cover [Image]
  ///
  /// [random] controls whether the chosen tile is chosen at random or whether the chosen tile is the 'first' tile in the store. Note that 'first' means alphabetically, not chronologically.
  ///
  /// Using random mode may take a while to generate if the random number is large.
  ///
  /// If using random mode, optionally set [maxRange] to an integer (1 <= [maxRange] <= [storeLength]) to only generate a random number between 0 and the specified number. Useful to reduce waiting times or enforce consistency.
  ///
  /// Returns `null` if there are no cached tiles.
  Future<Image?> coverImageAsync({
    required bool random,
    int? maxRange,
    double? size,
  }) async {
    final int storeLen = await storeLengthAsync;
    if (storeLen == 0) return null;

    if (!random && maxRange != null) {
      throw ArgumentError(
        'If not in random mode, `maxRange` must be left as `null`',
      );
    }
    if (maxRange != null && (maxRange < 1 || maxRange > storeLen)) {
      throw ArgumentError(
        'If specified, `maxRange` must be more than or equal to 1 and less than or equal to `storeLength`',
      );
    }

    final int? randInt = !random ? null : Random().nextInt(maxRange!);

    int i = 0;

    await for (final FileSystemEntity e in _access.tiles.list()) {
      if (i >= (randInt ?? 0)) {
        return Image.file(
          File(e.absolute.path),
          width: size,
          height: size,
        );
      }
      i++;
    }

    throw FallThroughError();
  }

  /// Watch for changes in the current store
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Only supported on some platforms. Will throw [UnsupportedError] if platform has no internal support (eg. OS X 10.6 and below).
  ///
  /// Control which changes are caught through the [fileSystemEvents] property, which takes [FileSystemEvent]s, and by default ignores modifications (ie. renaming).
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
    int fileSystemEvents = ~FileSystemEvent.modify,
  }) {
    if (!FileSystemEntity.isWatchSupported) {
      throw UnsupportedError(
        'Watching is not supported on the current platform',
      );
    }

    final stream =
        _access.real.watch(events: fileSystemEvents).map((e) => null).mergeAll([
      _access.metadata.watch(events: fileSystemEvents).map((e) => null),
      _access.stats.watch(events: fileSystemEvents).map((e) => null),
      _access.tiles.watch(events: fileSystemEvents).map((e) => null)
    ]);

    return debounce == null ? stream : stream.debounce(debounce);
  }
}
