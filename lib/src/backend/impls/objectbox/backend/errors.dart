// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

/// An [FMTCBackendError] that originates specifically from the
/// [FMTCObjectBoxBackend]
///
/// The [FMTCObjectBoxBackend] may also emit errors directly of type
/// [FMTCBackendError].
base class FMTCObjectBoxBackendError extends FMTCBackendError {}

/// Indicates that an export failed because the specified output path directory
/// was the same as the root directory
final class ExportInRootDirectoryForbidden extends FMTCObjectBoxBackendError {
  /// Indicates that an export failed because the specified output path directory
  /// was the same as the root directory
  ExportInRootDirectoryForbidden();

  @override
  String toString() =>
      'ExportInRootDirectoryForbidden: It is forbidden to export stores to the '
      'same directory as the `rootDirectory`';
}
