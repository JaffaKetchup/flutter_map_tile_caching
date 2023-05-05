// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

/// An [Exception] raised when FMTC failed to initialise a store
///
/// Can be thrown for multiple reasons. See [type] and
/// [FMTCInitialisationExceptionType] for more information.
///
/// A failed store initialisation will always result in the store being deleted
/// ASAP, regardless of its contents.
class FMTCInitialisationException implements Exception {
  /// Friendly message
  final String message;

  /// Programmatic error descriptor
  final FMTCInitialisationExceptionType type;

  /// Name of the store that could not be initialised, if known
  final String? storeName;

  /// Original error object (error is not directly thrown by FMTC), if applicable
  final Object? originalError;

  /// An [Exception] raised when FMTC failed to initialise a store
  ///
  /// Can be thrown for multiple reasons. See [type] and
  /// [FMTCInitialisationExceptionType] for more information.
  ///
  /// A failed store initialisation will always result in the store being deleted
  /// ASAP, regardless of its contents.
  @internal
  FMTCInitialisationException(
    this.message,
    this.type, {
    this.storeName,
    this.originalError,
  });

  @override
  String toString() => 'FMTCInitialisationException: $message';
}

/// Pragmatic error descriptor for a [FMTCInitialisationException.message]
///
/// See documentation on that object for more information.
enum FMTCInitialisationExceptionType {
  /// Paired with friendly message:
  /// "Failed to initialise a store because it was not listed as safe/stable on last
  /// initialisation."
  ///
  /// This signifies that the application has previously fatally crashed during
  /// initialisation, but that the initialisation safety system has now removed
  /// the store database.
  corruptedDatabase,

  /// Paired with friendly message:
  /// "Failed to initialise a store because Isar failed to open the database."
  ///
  /// This usually means the store database was valid, but Isar was not
  /// configured correctly or encountered another issue. Unlike
  /// [corruptedDatabase], this does not cause an app crash. Consult the
  /// [FMTCInitialisationException.originalError] for more information.
  isarFailure,
}
