// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

/// An [Exception] indicating that an operation was attempted on a damaged store
///
/// Can be thrown for multiple reasons. See [type] and
/// [FMTCDamagedStoreExceptionType] for more information.
class FMTCDamagedStoreException implements Exception {
  /// An [Exception] indicating that an operation was attempted on a damaged store
  ///
  /// Can be thrown for multiple reasons. See [type] and
  /// [FMTCDamagedStoreExceptionType] for more information.
  @internal
  FMTCDamagedStoreException(this.message, this.type);

  /// Friendly message
  final String message;

  /// Programmatic error descriptor
  final FMTCDamagedStoreExceptionType type;

  @override
  String toString() => 'FMTCDamagedStoreException: $message';
}

/// Pragmatic error descriptor for a [FMTCDamagedStoreException.message]
///
/// See documentation on that object for more information.
enum FMTCDamagedStoreExceptionType {
  /// Paired with friendly message:
  /// "Failed to perform an operation on a store due to the core descriptor
  /// being missing."
  missingStoreDescriptor,

  /// Paired with friendly message:
  /// "Something went wrong."
  unknown,
}
