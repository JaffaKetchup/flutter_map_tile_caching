// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

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
  final String storeName;

  StoreNotExists({required this.storeName});

  @override
  String toString() =>
      'StoreNotExists: The requested store "$storeName" did not exist';
}

/// Indicates that the specified store structure could not be created because it
/// already existed
final class StoreAlreadyExists extends FMTCBackendError {
  final String storeName;

  StoreAlreadyExists({required this.storeName});

  @override
  String toString() =>
      'StoreAlreadyExists: The requested store "$storeName" already existed';
}
