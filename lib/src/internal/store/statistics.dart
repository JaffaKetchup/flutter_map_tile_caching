import 'dart:io';

import 'package:collection/collection.dart';

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
  StoreStats(this._storeDirectory, [this._forceRecalculation = false])
      : _access = StoreAccess(_storeDirectory);

  /// Shorthand for [StoreDirectory.access], used commonly throughout
  final StoreAccess _access;

  /// Force re-calculation for all statistics instead of retrieving from stats cache
  StoreStats get noCache => StoreStats(_storeDirectory, true);

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

  /// Retrieve the size of the store in kibibytes (KiB)
  ///
  /// For asynchronous version, see [storeSizeAsync].
  ///
  /// Includes all files beneath the store, not necessarily just tiles.
  double get storeSize => double.parse(_csgSync(
        'size',
        () {
          int totalSize = 0;
          for (FileSystemEntity e in _access.real.listSync(recursive: true)) {
            totalSize += e is File ? e.lengthSync() : 0;
          }

          return totalSize / 1024;
        },
      ));

  /// Retrieve the size of the store in kibibytes (KiB)
  ///
  /// For asynchronous version, see [storeSize].
  ///
  /// Includes all files beneath the store, not necessarily just tiles.
  Future<double> get storeSizeAsync async => double.parse(await _csgAsync(
        'size',
        () async {
          return (await _access.real.list(recursive: true).asyncMap((e) async {
                if (e is! File) return 0;

                try {
                  return await e.length();
                } catch (e) {
                  return 0;
                }
              }).toList())
                  .sum /
              1024;
        },
      ));

  /// Retrieve the number of stored tiles in a store
  ///
  /// For asynchronous version, see [storeLengthAsync].
  ///
  /// Only includes tiles stored, not necessarily all files.
  int get storeLength => int.parse(_csgSync(
        'length',
        () => _access.tiles.listSync().length,
      ));

  /// Retrieve the number of stored tiles in a store
  ///
  /// For synchronous version, see [storeLength].
  ///
  /// Only includes tiles stored, not necessarily all files.
  Future<int> get storeLengthAsync async => int.parse(await _csgAsync(
        'length',
        () async => await _access.tiles.list().length,
      ));
}
