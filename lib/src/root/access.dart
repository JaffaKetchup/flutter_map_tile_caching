// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import '../internal/exts.dart';
import 'directory.dart';

/// Provides direct filesystem access paths to a [RootDirectory] - use with caution
class RootAccess {
  /// The store directory to provide access paths to
  final RootDirectory _rootDirectory;

  /// Provides direct filesystem access paths to a [RootDirectory] - use with caution
  RootAccess(this._rootDirectory) {
    real = _rootDirectory.rootDirectory;
    stores = real >> 'stores';
    stats = real >> 'stats';
    recovery = real >> 'recovery';
  }

  /// The real [Directory] of the [RootDirectory]
  ///
  /// Note that this is equivalent to just using [RootDirectory.rootDirectory], but is provided for consistency. It is recommended to use this whenever possible.
  late final Directory real;

  /// The sub[Directory] used to store stores
  late final Directory stores;

  /// The sub[Directory] used to store cached statistics
  late final Directory stats;

  /// The sub[Directory] used to store recovery information
  late final Directory recovery;
}
