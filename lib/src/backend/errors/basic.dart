// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'errors.dart';

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
      'RootAlreadyInitialised: The requested backend/root could not be '
      'initialised because it was already initialised';
}

/// Indicates that the specified store structure was not available for use in
/// operations, likely because it didn't exist
final class StoreNotExists extends FMTCBackendError {
  StoreNotExists({required this.storeName});

  /// The referenced store name
  final String storeName;

  @override
  String toString() =>
      'StoreNotExists: The requested store "$storeName" did not exist';
}
