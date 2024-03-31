// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'errors.dart';

/// A subset of [FMTCBackendError]s that indicates a failure during import or
/// export, due to the extended reason
base class ImportExportError extends FMTCBackendError {}

/// Indicates that the specified path to import from or export to did exist, but
/// was not a file
final class ImportExportPathNotFile extends ImportExportError {
  /// Indicates that the specified path to import from or export to did exist,
  /// but was not a file
  ImportExportPathNotFile();

  @override
  String toString() =>
      'ImportPathNotFile: The specified import/export path existed, but was not '
      'a file.';
}

/// Indicates that the specified file to import did not exist/could not be found
final class ImportPathNotExists extends ImportExportError {
  /// Indicates that the specified file to import did not exist/could not be
  /// found
  ImportPathNotExists({required this.path});

  /// The specified path to the import file
  final String path;

  @override
  String toString() =>
      'ImportPathNotExists: The specified import file ($path) did not exist.';
}

/// Indicates that the import file was not of the expected standard, because it
/// did not contain the appropriate footer signature
///
/// The last bytes of the file must be hex "FF FF 46 4D 54 43" ("**FMTC").
final class ImportFileNotFMTCStandard extends ImportExportError {
  /// Indicates that the import file was not of the expected standard, because it
  /// did not contain the appropriate footer signature
  ///
  /// The last bytes of the file must be hex "FF FF 46 4D 54 43" ("**FMTC").
  ImportFileNotFMTCStandard();

  @override
  String toString() =>
      'ImportFileNotFMTCStandard: The import file was not of the expected '
      'standard.';
}

/// Indicates that the import file was exported from a different FMTC backend,
/// and is not compatible with the current backend
///
/// The bytes prior to the footer signature should an identifier (eg. the name)
/// of the exporting backend proceeded by hex "FF FF FF FF".
final class ImportFileNotBackendCompatible extends ImportExportError {
  /// Indicates that the import file was exported from a different FMTC backend,
  /// and is not compatible with the current backend
  ///
  /// The bytes prior to the footer signature should an identifier (eg. the name)
  /// of the exporting backend proceeded by hex "FF FF FF FF".
  ImportFileNotBackendCompatible();

  @override
  String toString() =>
      'ImportFileNotBackendCompatible: The import file was exported from a '
      'different FMTC backend, and is not compatible with the current backend';
}
