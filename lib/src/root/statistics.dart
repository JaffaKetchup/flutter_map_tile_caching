import 'dart:io';

import '../internal/exts.dart';
import 'access.dart';
import 'directory.dart';

/// Provides statistics about a [RootDirectory]
class RootStats {
  /// The root directory to provide statistics about
  final RootDirectory _rootDirectory;

  /// Internally force re-calculation for all statistics, instead of retrieving from cache via [_csgSync] or [_csgAsync]
  final bool _forceRecalculation;

  /// Provides statistics about a [RootDirectory]
  RootStats(this._rootDirectory, [this._forceRecalculation = false])
      : _access = RootAccess(_rootDirectory);

  /// Shorthand for [RootDirectory.access], used commonly throughout
  final RootAccess _access;

  /// Force re-calculation for all statistics instead of retrieving from stats cache
  RootStats get noCache => RootStats(_rootDirectory, true);

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

  /// Retrieve the size of the root in kibibytes (KiB)
  ///
  /// For asynchronous version, see [rootSizeAsync].
  ///
  /// Includes all files beneath the root, not necessarily just tiles.
  double get rootSize => double.parse(_csgSync(
        'size',
        () {},
      ));

  /// Retrieve the size of the root in kibibytes (KiB)
  ///
  /// For asynchronous version, see [rootSize].
  ///
  /// Includes all files beneath the root, not necessarily just tiles.
  Future<double> get rootSizeAsync async => double.parse(await _csgAsync(
        'size',
        () async {},
      ));

  /// Retrieve the number of stored tiles in all sub-stores.
  ///
  /// For asynchronous version, see [rootLengthAsync].
  ///
  /// Only includes tiles stored, not necessarily all files.
  int get rootLength => int.parse(_csgSync(
        'length',
        () {},
      ));

  /// Retrieve the number of stored tiles in all sub-stores.
  ///
  /// For synchronous version, see [rootLength].
  ///
  /// Only includes tiles stored, not necessarily all files.
  Future<int> get rootLengthAsync async => int.parse(await _csgAsync(
        'length',
        () async {},
      ));
}
