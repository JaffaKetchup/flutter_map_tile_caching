// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/foundation.dart';

import 'fmtc_settings.dart';

/// Object to return from any filesystem sanitiser defined in [FMTCSettings.filesystemSanitiser]
///
/// [FilesystemSanitiserResult.validOutput] must be sanitised to be safe enough to be used in the filesystem. [FilesystemSanitiserResult.errorMessages] can be empty if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
///
/// If the method is used internally in a validation situation, the output must be equal to the input, otherwise the error messages are thrown. This is, for example, the situation when managing stores and names. If the method is used internally in a sanitisation situation, error messages are ignored. This is, for example, the situation when storing map tiles.
class FilesystemSanitiserResult {
  /// Must be sanitised to be safe enough to be used in the filesystem
  final String validOutput;

  /// Can be empty (default) if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
  final List<String> errorMessages;

  /// Object to return from any filesystem sanitiser defined in [FMTCSettings.filesystemSanitiser]
  ///
  /// [FilesystemSanitiserResult.validOutput] must be sanitised to be safe enough to be used in the filesystem. [FilesystemSanitiserResult.errorMessages] can be empty if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
  ///
  /// If the method is used internally in a validation situation, the output must be equal to the input, otherwise the error messages are thrown. This is, for example, the situation when managing stores and names. If the method is used internally in a sanitisation situation, error messages are ignored. This is, for example, the situation when storing map tiles.
  FilesystemSanitiserResult({
    required this.validOutput,
    this.errorMessages = const [],
  });

  @override
  String toString() =>
      'FilesystemSanitiserResult(validOutput: $validOutput, errorMessages: $errorMessages)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilesystemSanitiserResult &&
        other.validOutput == validOutput &&
        listEquals(other.errorMessages, errorMessages);
  }

  @override
  int get hashCode => validOutput.hashCode ^ errorMessages.hashCode;
}
