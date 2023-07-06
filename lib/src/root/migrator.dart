// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: comment_references

part of flutter_map_tile_caching;

/// Manage migration for file structure across FMTC versions
class RootMigrator {
  const RootMigrator._();

  /// Migrates a v6 file structure to a v7 structure
  ///
  /// Note that this method can be slow on large tilesets, so it's best to offer
  /// a choice to your users as to whether they would like to migrate, or just
  /// lose all stored tiles.
  ///
  /// Checks within `getApplicationDocumentsDirectory()` and
  /// `getTemporaryDirectory()` for a directory named 'fmtc'. Alternatively,
  /// specify a [customDirectory] to search for 'fmtc' within.
  ///
  /// In order to migrate the tiles to the new format, [urlTemplates] must be
  /// used. Pass every URL template used to store any of the tiles that might be
  /// in the store. Specifying an empty list will use the preset OSM tile servers
  /// only.
  ///
  /// Set [deleteOldStructure] to `false` to keep the old structure. If a store
  /// exists with the same name, it will not be overwritten, and the
  /// [deleteOldStructure] parameter will be followed regardless.
  ///
  /// Only supports placeholders in the normal flutter_map form, those that meet
  /// the RegEx: `\{ *([\w_-]+) *\}`. Only supports tiles that were sanitised
  /// with the default sanitiser included in FMTC.
  ///
  /// Recovery information and cached statistics will be lost.
  ///
  /// Returns `null` if no structure root was found, otherwise a [Map] of the
  /// store names to the number of failed tiles (tiles that could not be matched
  /// to any of the [urlTemplates]), or `null` if it was skipped because there
  /// was an existing store with the same name. A successful migration will have
  /// all values 0.
  Future<Map<String, int?>?> fromV6({
    required List<String> urlTemplates,
    Directory? customDirectory,
    bool deleteOldStructure = true,
  }) async {
    // Prepare the migration regular expressions
    final placeholderRegex = RegExp(r'\{ *([\w_-]+) *\}');
    final matchables = [
      ...[
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ...urlTemplates,
      ].map((url) {
        final sanitised = _defaultFilesystemSanitiser(url).validOutput;

        return [
          sanitised.replaceAll('.', r'\.').replaceAll(placeholderRegex, '.+?'),
          sanitised,
          url,
        ];
      }),
    ];

    // Search for the previous structure
    final normal = (await getApplicationDocumentsDirectory()) >> 'fmtc';
    final temporary = (await getTemporaryDirectory()) >> 'fmtc';
    final custom = customDirectory == null ? null : customDirectory >> 'fmtc';
    final root = await normal.exists()
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
    if (!await oldStores.exists()) return {};

    // Prepare results map
    final Map<String, int?> results = {};

    // Migrate stores
    await for (final storeDirectory
        in oldStores.list().whereType<Directory>()) {
      final name = path.basename(storeDirectory.absolute.path);
      results[name] = 0;

      // Ignore this store if a counterpart already exists
      if (FMTC.instance(name).manage.ready) {
        results[name] = null;
        continue;
      }
      await FMTC.instance(name).manage.createAsync();
      final store = FMTCRegistry.instance(name);

      // Migrate tiles in transaction batches of 250
      await for (final List<File> tiles
          in (storeDirectory >> 'tiles').list().whereType<File>().slices(250)) {
        await store.writeTxn(
          () async => store.tiles.putAll(
            (await Future.wait(
              tiles.map(
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

                  results[name] = results[name]! + 1;
                  return null;
                },
              ),
            ))
                .nonNulls
                .toList(),
          ),
        );
      }

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
    if (deleteOldStructure && await oldStores.exists()) {
      await oldStores.delete(recursive: true);
    }

    return results;
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

class _FilesystemSanitiserResult {
  final String validOutput;
  final List<String> errorMessages;

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
  int get hashCode => Object.hash(validOutput, errorMessages);
}
