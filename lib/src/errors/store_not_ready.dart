// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

/// An [Error] indicating that a store did not exist when it was expected to
///
/// Commonly thrown by statistic operations, but can be thrown from multiple
/// other places.
class FMTCStoreNotReady extends Error {
  /// The store name that the method tried to access
  final String storeName;

  /// A human readable description of the error, and steps that may be taken to
  /// avoid this error being thrown again
  final String message;

  /// Whether this store was registered internally.
  ///
  /// Represents a serious internal FMTC error if `true`, as represented by
  /// [message].
  final bool registered;

  /// An [Error] indicating that a store did not exist when it was expected to
  ///
  /// Commonly thrown by statistic operations, but can be thrown from multiple
  /// other places.
  @internal
  FMTCStoreNotReady({
    required this.storeName,
    required this.registered,
  }) : message = registered
            ? "The store ('$storeName') was registered, but the underlying database was not open, at this time. This is an erroneous state in FMTC: if this error appears in your application, please open an issue on GitHub immediately."
            : "The store ('$storeName') does not exist at this time, and is not ready. Ensure that your application does not use the method that triggered this error unless it is sure that the store will exist at this point.";

  /// Similar to [message], but suitable for console output in an unknown context
  @override
  String toString() => 'FMTCStoreNotReady: $message';
}
