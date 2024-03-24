// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part 'basic.dart';
part 'import_export.dart';

/// An error to be thrown by backend implementations in known events only
///
/// A backend can create custom errors of this type, which is useful to show
/// that the backend is throwing a known expected error, rather than an
/// unexpected one.
base class FMTCBackendError extends Error {}
