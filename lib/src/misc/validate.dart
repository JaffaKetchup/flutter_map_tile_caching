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

/// Public validator (semi-exposing internal [safeFilesystemString]) used to ensure strings are safe for storage in the filesystem
///
/// This is useful to validate user-facing input for store names (such as in `TextFormField`s), and ensure that they:
///  - comply with limitations of the filesystem
///  - don't cause problems where sanitised input causes duplication
///
/// The first cannot be guaranteed 100%, as control characters (except NUL) and potential reserved names are not checked; but it is better than nothing.
///
/// To understand the latter, imagine your user inputs two store names, 'a\*b\*c' and 'a:b:c'. If this were to just sanitise the string, they would end up with the same name 'a_b_c', as '*' and ':' are invalid characters. Therefore, the user may expect two stores but only get one. Likewise, the user would see a different name to the one they inputted.
///
/// The internal method mentioned above, however can be used in two modes: sanitise or throw. Sanitise mode is used where duplications are impossible and the end-user should never see the exact name: such as for the storage of tiles as images in the filesystem. Throw mode is used in the constructors of [StorageCachingTileProvider] and [MapCachingManager], and prevents invalid input for the reasons mentioned above.
///
/// Therefore, to prevent unexpected errors on construction, it is recommended to use this as a validator for user inputted store names: it can be put right in the `validator` property!
///
/// A `null` output means the string is valid, otherwise appropriate error text is outputted (in English).
String? validateFilesystemString(String? storeName) {
  try {
    safeFilesystemString(inputString: storeName ?? '', throwIfInvalid: true);
    return null;
  } catch (e) {
    return e as String;
  }
}
