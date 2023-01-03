// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: avoid_print, comment_references

part of '../../flutter_map_tile_caching.dart';

/// Manage migration for file structure across FMTC versions
class RootMigrator {
  RootMigrator._();

  /// 'fromV4' is deprecated and shouldn't be used. Effort to maintain this length of backwards compatibility has become too great, so any structures remaining on v4 will need migrating manually or disposing of altogether. This remnant will be removed in a future update.
  @Deprecated(
    'Effort to maintain this length of backwards compatibility has become too great, so any structures remaining on v4 will need migrating manually or disposing of altogether. This remnant will be removed in a future update',
  )
  Future<Never> fromV4({Directory? customSearch}) async =>
      throw UnsupportedError(
        "'fromV4' is deprecated and shouldn't be used. Effort to maintain this length of backwards compatibility has become too great, so any structures remaining on v4 will need migrating manually or disposing of altogether. This remnant will be removed in a future update.",
      );

  /// Migrates a v6 file structure to a v7 structure
  ///
  /// Note that this method can be inefficient on large tilesets, so it's best
  /// to offer a choice to your users as to whether they would like to migrate,
  /// or just loose all stored tiles.
  ///
  /// Checks within `getApplicationDocumentsDirectory()` and
  /// `getTemporaryDirectory()` for a directory named 'fmtc'. Alternatively,
  /// specify a [customDirectory] to search for 'fmtc' within.
  ///
  /// In order to migrate the tiles to the new format, [urlTemplates] must be
  /// used. Pass every URL template used to store any of the tiles that might be
  /// in the store. Specifying `null` will use the preset OSM tile server only.
  ///
  /// Set [deleteOldStructure] to `false` to keep the old structure.
  ///
  /// Only supports placeholders in the normal flutter_map form, those that meet
  /// the RegEx: `\{ *([\w_-]+) *\}`. Only supports tiles that were sanitised
  /// with the default sanitiser included in FMTC.
  ///
  /// Recovery information and cached statistics will be lost.
  ///
  /// Returns `null` if no structure was found or migration failed, otherwise
  /// the number of tiles that could not be matched to any of the [urlTemplates].
  /// A fully sucessful migration will return 0.
  Future<int?> fromV6({
    required List<String>? urlTemplates,
    Directory? customDirectory,
    bool deleteOldStructure = true,
  }) async {
    final placeholderRegex = RegExp(r'\{ *([\w_-]+) *\}');

    final List<List<String>> matchables = [
      ...[
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ...urlTemplates ?? [],
      ].map((url) {
        final sanitised = _filesystemSanitiseValidate(
          inputString: url,
          throwIfInvalid: false,
        );
        return [
          sanitised.replaceAll(placeholderRegex, '(.*?)'),
          sanitised,
          url,
        ];
      }),
    ];

    // Search for the previous structure
    final Directory normal =
        (await getApplicationDocumentsDirectory()) >> 'fmtc';
    final Directory temporary = (await getTemporaryDirectory()) >> 'fmtc';
    final Directory? custom =
        customDirectory == null ? null : customDirectory >> 'fmtc';
    final Directory? root = await normal.exists()
        ? normal
        : await temporary.exists()
            ? temporary
            : custom == null
                ? null
                : await custom.exists()
                    ? custom
                    : null;
    if (root == null) return null;

    // Delete recovery files and cached statistics
    if (deleteOldStructure) {
      final oldRecovery = root >> 'recovery';
      if (await oldRecovery.exists()) await oldRecovery.delete(recursive: true);
      final oldStats = root >> 'stats';
      if (await oldStats.exists()) await oldStats.delete(recursive: true);
    }

    // Don't continue migration if there are no stores
    final oldStores = root >> 'stores';
    if (!await oldStores.exists()) return null;

    // Migrate stores
    int failedTiles = 0;
    await for (final storeDirectory
        in oldStores.list().whereType<Directory>()) {
      final store = FMTCRegistry.instance.storeDatabases[await FMTC
          .instance(path.basename(storeDirectory.absolute.path))
          .manage
          ._advancedCreate()]!;

      // Migrate tiles
      await store.writeTxn(
        () async => store.tiles.putAll(
          await (storeDirectory >> 'tiles')
              .list()
              .whereType<File>()
              .asyncMap(
                (f) async {
                  final filename = path.basename(f.absolute.path);
                  final Map<String, String> placeholderValues = {};

                  for (final e in matchables) {
                    if (!RegExp('^${e[0]}\$', multiLine: true)
                        .hasMatch(filename)) {
                      continue;
                    }

                    String filenameChangable = filename;
                    List<String> filenameSplit = filename.split('')..add('');

                    for (final match in placeholderRegex.allMatches(e[1])) {
                      final templateValue =
                          e[1].substring(match.start, match.end);
                      final afterChar = (e[1].split('')..add(''))[match.end];

                      final memory = StringBuffer();
                      int i = match.start;
                      for (; filenameSplit[i] != afterChar; i++) {
                        memory.write(filenameSplit[i]);
                      }
                      filenameChangable = filenameChangable.replaceRange(
                        match.start,
                        i,
                        templateValue,
                      );
                      filenameSplit = filenameChangable.split('')..add('');

                      placeholderValues[templateValue.substring(
                        1,
                        templateValue.length - 1,
                      )] = memory.toString();
                    }

                    return DbTile(
                      url:
                          TileLayer().templateFunction(e[2], placeholderValues),
                      bytes: await f.readAsBytes(),
                    );
                  }

                  failedTiles++;
                  return null;
                },
              )
              .whereNotNull()
              .toList(),
        ),
      );

      // Migrate metadata
      await store.writeTxn(
        () async => store.metadata.putAll(
          await (storeDirectory >> 'metadata')
              .list()
              .whereType<File>()
              .asyncMap(
                (f) async => DbMetadata(
                  name: path.basename(f.absolute.path).split('.metadata')[0],
                  data: await f.readAsString(),
                ),
              )
              .toList(),
        ),
      );
    }

    // Delete store files
    await oldStores.delete(recursive: true);

    return failedTiles;
  }
}

//! OLD FILESYSTEM SANITISER CODE !//

_FilesystemSanitiserResult _defaultFilesystemSanitiser(String input) {
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

  return _FilesystemSanitiserResult(
    validOutput: validOutput,
    errorMessages: errorMessages,
  );
}

/// An [Exception] thrown by [FMTCSettings.filesystemSanitiser] indicating that the supplied string was invalid
///
/// The [_message] gives a reason and more information.
class _InvalidFilesystemString implements Exception {
  final String _message;

  /// An [Exception] thrown by [FMTCSettings.filesystemSanitiser] indicating that the supplied string was invalid
  ///
  /// The [_message] gives a reason and more information.
  _InvalidFilesystemString(this._message);

  @override
  String toString() => 'InvalidFilesystemString: $_message';
  String toStringUserFriendly() => _message;
}

String _filesystemSanitiseValidate({
  required String inputString,
  required bool throwIfInvalid,
}) {
  final _FilesystemSanitiserResult output =
      _defaultFilesystemSanitiser(inputString);

  if (throwIfInvalid && output.errorMessages.isNotEmpty) {
    throw _InvalidFilesystemString(
      'The input string was unsuitable for filesystem use, due to the following reasons:\n${output.errorMessages.map((e) => ' - $e').join('\n')}',
    );
  }
  return output.validOutput;
}

/// Object to return from any filesystem sanitiser defined in [FMTCSettings.filesystemSanitiser]
///
/// [FilesystemSanitiserResult.validOutput] must be sanitised to be safe enough to be used in the filesystem. [FilesystemSanitiserResult.errorMessages] can be empty if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
///
/// If the method is used internally in a validation situation, the output must be equal to the input, otherwise the error messages are thrown. This is, for example, the situation when managing stores and names. If the method is used internally in a sanitisation situation, error messages are ignored. This is, for example, the situation when storing map tiles.
class _FilesystemSanitiserResult {
  /// Must be sanitised to be safe enough to be used in the filesystem
  final String validOutput;

  /// Can be empty (default) if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
  final List<String> errorMessages;

  /// Object to return from any filesystem sanitiser defined in [FMTCSettings.filesystemSanitiser]
  ///
  /// [FilesystemSanitiserResult.validOutput] must be sanitised to be safe enough to be used in the filesystem. [FilesystemSanitiserResult.errorMessages] can be empty if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
  ///
  /// If the method is used internally in a validation situation, the output must be equal to the input, otherwise the error messages are thrown. This is, for example, the situation when managing stores and names. If the method is used internally in a sanitisation situation, error messages are ignored. This is, for example, the situation when storing map tiles.
  _FilesystemSanitiserResult({
    required this.validOutput,
    this.errorMessages = const [],
  });

  @override
  String toString() =>
      'FilesystemSanitiserResult(validOutput: $validOutput, errorMessages: $errorMessages)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _FilesystemSanitiserResult &&
        other.validOutput == validOutput &&
        listEquals(other.errorMessages, errorMessages);
  }

  @override
  int get hashCode => validOutput.hashCode ^ errorMessages.hashCode;
}
