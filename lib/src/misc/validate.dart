import 'package:meta/meta.dart';

/// Makes any store name string safe for storing in a filesystem structure, platform-universally
///
/// Note that this is not 100% secure/guaranteed: eg. control characters (except NUL) and potential reserved names are not checked.
///
/// Use [throwIfInvalid] if the output string might be:
///
///  - shown to an end user
///  - cause confusion during debugging
///  - a duplicate of another sanitized file within the same directory
///
/// ... otherwise it should be `false`.
///
/// [enforce255MaxLength] will take the last 255 chars of the [inputString]. This is useful on iOS systems.
///
/// See [StoreDirectory.validateFilesystemString] for a public facing validator.
@internal
String safeFilesystemString({
  required String inputString,
  required bool throwIfInvalid,
  bool enforce255MaxLength = true,
}) {
  String alteredString = inputString;

  // Ensure is not empty
  if (alteredString.isEmpty) {
    if (throwIfInvalid) {
      throw 'The name cannot be empty';
    }
    alteredString = '_';
  }

  // Trim
  alteredString = inputString.trim();
  if (alteredString != inputString && throwIfInvalid) {
    throw 'The name cannot contain leading and/or trailing spaces';
  }

  // Ensure is not just '.'
  if (alteredString.replaceAll('.', '').isEmpty) {
    if (throwIfInvalid) {
      throw 'The name cannot consist of only periods (.)';
    }
    alteredString = alteredString.replaceAll('.', '_');
  }

  // Apply other character rules with general RegExp
  alteredString =
      alteredString.replaceAll(RegExp(r'[\\\\/\:\*\?\"\<\>\|]'), '_');
  if (alteredString != inputString && throwIfInvalid) {
    throw 'The name cannot contain invalid characters: \'[NUL]\\/:*?"<>|\'';
  }

  // Reduce string to under 255 chars (keeps end)
  if (enforce255MaxLength && alteredString.length > 255) {
    alteredString = alteredString.substring(alteredString.length - 255);
    if (alteredString != inputString && throwIfInvalid) {
      throw 'The name cannot contain more than 255 characters';
    }
  }

  return alteredString;
}
