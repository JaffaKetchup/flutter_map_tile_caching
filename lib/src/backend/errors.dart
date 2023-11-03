/// Indicates that the backend/root structure (ie. database and/or directory) was
/// not available for use in operations, because either:
///  * it was already closed
///  * it was never created
///  * it was invalid/corrupt
///  * ... or it was otherwise unavailable
///
/// To be thrown by backend implementations.
class RootUnavailable extends Error {
  @override
  String toString() =>
      'RootUnavailable: The requested backend/root was unavailable';
}

/// Indicates that the specified store structure was not available for use in
/// operations, likely because it didn't exist
///
/// To be thrown by backend implementations.
class StoreUnavailable extends Error {
  final String storeName;

  StoreUnavailable({required this.storeName});

  @override
  String toString() =>
      'StoreUnavailable: The requested store "$storeName" was unavailable';
}
