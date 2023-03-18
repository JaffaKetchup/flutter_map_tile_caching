// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

/// An [Exception] raised when FMTC failed to initialise
///
/// May indicate a previously fatal crash due to a corrupted database. If this is
/// the case, [source] will be `null`, [wasFatal] will be `true`, and the
/// corrupted database will be deleted.
class FMTCInitialisationException implements Exception {
  /// The original error object
  ///
  /// If `null` indicates a previously fatal crash due to a corrupted database. If
  /// this is the case, [wasFatal] will be `true`, and the corrupted database will
  /// be deleted.
  final Object? source;

  /// Indicates whether there was a previously fatal crash due to a corrupted
  /// database. If this is the case, [source] will be `null`, and the corrupted
  /// database will be deleted.
  final bool wasFatal;

  /// An [Exception] raised when FMTC failed to initialise
  ///
  /// May indicate a previously fatal crash due to a corrupted database. If this is
  /// the case, [source] will be `null`, [wasFatal] will be `true`, and the
  /// corrupted database will be deleted.
  @internal
  FMTCInitialisationException({
    required this.source,
  }) : wasFatal = source == null;

  /// Converts the [source] into a string
  @override
  String toString() => source.toString();
}
