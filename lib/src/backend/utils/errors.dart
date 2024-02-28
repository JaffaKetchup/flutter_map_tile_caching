// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import '../export_external.dart';

/// A method called by FMTC internals when an exception occurs in a backend
///
/// A thrown [FMTCBackendError] will NOT result in this method being invoked, as
/// that error should be fixed in code, and should not occur at runtime. It will
/// always be thrown.
///
/// [initialisationFailure] indicates whether the error occured during
/// intialisation. If it is `true`, then the error was fatal and will have
/// killed the backend. Otherwise, the backend should still recieve and respond
/// to future operations.
///
/// Other [Exception]s/[Error]s will result in this method being invoked, with a
/// modified [StackTrace] that gives an indication as to where the issue occured
/// internally, useful should a bug need to be reported. The trace will not
/// include where the original method that caused the error was invoked. This
/// exception/error may or may not be an issue directly in FMTC, it may be an
/// issue in the usage of a dependency (such as an exception caused by
/// exceeding a database's storage limit).
///
/// If the callback returns `true`, then FMTC will not continue to handle the
/// error. Otherwise, FMTC will also throw the exception/error. If the callback
/// is not defined (in [FMTCBackend.initialise]), then FMTC will throw the
/// exception/error.
typedef FMTCExceptionHandler = bool Function({
  required Object? exception,
  required StackTrace stackTrace,
  required bool initialisationFailure,
});

/// An error to be thrown by backend implementations in known events only
///
/// A backend can create custom errors of this type, which is useful to show
/// that the backend is throwing a known expected error, rather than an
/// unexpected one.
base class FMTCBackendError extends Error {}

/// Indicates that the backend/root structure (ie. database and/or directory) was
/// not available for use in operations, because either:
///  * it was already closed
///  * it was never created
///  * it was closed immediately whilst this operation was in progress
final class RootUnavailable extends FMTCBackendError {
  @override
  String toString() =>
      'RootUnavailable: The requested backend/root was unavailable';
}

/// Indicates that the backend/root structure could not be initialised, because
/// it was already initialised
final class RootAlreadyInitialised extends FMTCBackendError {
  @override
  String toString() =>
      'RootAlreadyInitialised: The requested backend/root could not be initialised because it was already initialised';
}

/// Indicates that the specified store structure was not available for use in
/// operations, likely because it didn't exist
final class StoreNotExists extends FMTCBackendError {
  StoreNotExists({required this.storeName});

  final String storeName;

  @override
  String toString() =>
      'StoreNotExists: The requested store "$storeName" did not exist';
}

/// Indicates that the specified store structure could not be created because it
/// already existed
final class StoreAlreadyExists extends FMTCBackendError {
  StoreAlreadyExists({required this.storeName});

  final String storeName;

  @override
  String toString() =>
      'StoreAlreadyExists: The requested store "$storeName" already existed';
}
