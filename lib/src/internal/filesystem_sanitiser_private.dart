// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import '../fmtc.dart';
import '../settings/filesystem_sanitiser_public.dart';
import '../settings/fmtc_settings.dart';

FilesystemSanitiserResult defaultFilesystemSanitiser(String input) {
  final List<String> errorMessages = [];
  String validOutput = input;

  // Apply other character rules with general RegExp
  validOutput = validOutput.replaceAll(RegExp(r'[\\\\/\:\*\?\"\<\>\|]'), '_');
  if (validOutput != input) {
    errorMessages
        .add('The name cannot contain invalid characters: \'[NUL]\\/:*?"<>|\'');
  }

  // Trim
  validOutput = validOutput.trim();
  if (validOutput != input) {
    errorMessages.add('The name cannot contain leading and/or trailing spaces');
  }

  // Ensure is not empty
  if (validOutput.isEmpty) {
    errorMessages.add('The name cannot be empty');
    validOutput = '_';
  }

  // Ensure is not just '.'
  if (validOutput.replaceAll('.', '').isEmpty) {
    errorMessages.add('The name cannot consist of only periods (.)');
    validOutput = validOutput.replaceAll('.', '_');
  }

  // Reduce string to under 255 chars (keeps end)
  if (validOutput.length > 255) {
    validOutput = validOutput.substring(validOutput.length - 255);
    if (validOutput != input) {
      errorMessages.add('The name cannot contain more than 255 characters');
    }
  }

  return FilesystemSanitiserResult(
    validOutput: validOutput,
    errorMessages: errorMessages,
  );
}

/// An [Exception] thrown by [FMTCSettings.filesystemSanitiser] indicating that the supplied string was invalid
///
/// The [_message] gives a reason and more information.
class InvalidFilesystemString implements Exception {
  final String _message;

  /// An [Exception] thrown by [FMTCSettings.filesystemSanitiser] indicating that the supplied string was invalid
  ///
  /// The [_message] gives a reason and more information.
  InvalidFilesystemString(this._message);

  @override
  String toString() => 'InvalidFilesystemString: $_message';
  String toStringUserFriendly() => _message;
}

String filesystemSanitiseValidate({
  required String inputString,
  required bool throwIfInvalid,
}) {
  final FilesystemSanitiserResult output =
      FMTC.instance.settings.filesystemSanitiser(inputString);

  if (throwIfInvalid && output.errorMessages.isNotEmpty) {
    throw InvalidFilesystemString(
      'The input string was unsuitable for filesystem use, due to the following reasons:\n${output.errorMessages.map((e) => ' - $e').join('\n')}',
    );
  }
  return output.validOutput;
}
