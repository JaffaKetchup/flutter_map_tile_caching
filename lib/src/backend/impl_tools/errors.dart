/// Indicates that the backend/root structure (ie. database and/or directory) was
/// not available for use in operations, because either:
///  * it was already closed
///  * it was never created
///  * it was invalid/corrupt
///  * ... or it was otherwise unavailable
///
/// To be thrown by backend implementations. For resolution by end-user.
class RootUnavailable extends Error {
  @override
  String toString() =>
      'RootUnavailable: The requested backend/root was unavailable';
}

/// Indicates that the backend/root structure could not be initialised, because
/// it was already initialised.
///
/// Try destroying it first.
///
/// To be thrown by backend implementations. For resolution by end-user.
class RootAlreadyInitialised extends Error {
  @override
  String toString() =>
      'RootUnavailable: The requested backend/root could not be initialised because it was already initialised';
}

/// Indicates that the specified store structure was not available for use in
/// operations, likely because it didn't exist
///
/// To be thrown by backend implementations. For resolution by end-user.
class StoreUnavailable extends Error {
  final String storeName;

  StoreUnavailable({required this.storeName});

  @override
  String toString() =>
      'StoreUnavailable: The requested store "$storeName" was unavailable';
}

/// Indicates that the specified tile could not be updated because it did not
/// already exist
///
/// To be thrown by backend implementations. For resolution by FMTC.
///
/// If you have this error in your application, please file a bug report.
class TileCannotUpdate extends Error {
  final String url;

  TileCannotUpdate({required this.url});

  @override
  String toString() =>
      'TileCannotUpdate: The requested tile ("$url") did not exist, and so cannot be updated';
}

/// Indicates that the backend implementation does not support the invoked
/// synchronous operation.
///
/// Use the asynchronous version instead.
///
/// Note that there is no equivalent error for async operations: if there is no
/// specific async version of an operation, it should redirect to the sync
/// version.
///
/// To be thrown by backend implementations. For resolution by end-user.
class SyncOperationUnsupported extends Error {
  @override
  String toString() =>
      'SyncOperationUnsupported: The backend implementation does not support the invoked synchronous operation.';
}
