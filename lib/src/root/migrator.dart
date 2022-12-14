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

  /*
  final Map<String, String> matchables = {
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png': {
        RegExp('{(.*?)}'): RegExp('([0-9]+)'),
      },
      ...urlTemplates ?? {},
    }.map(
      (url, v) {
        final String filesystemSafe = filesystemSanitiseValidate(
          inputString: url,
          throwIfInvalid: false,
        );

        String withRegex = filesystemSafe;
        for (final replaceWith in v.entries) {
          withRegex =
              withRegex.replaceAll(replaceWith.key, replaceWith.value.pattern);
        }

        return MapEntry(filesystemSafe, withRegex);
      },
    );

*/

  /// Migrates a v6 file structure to a v7 structure
  ///
  /// Checks within `getApplicationDocumentsDirectory()` and
  /// `getTemporaryDirectory()` for a directory named 'fmtc'. Alternatively,
  /// specify a [customDirectory] to search for 'fmtc' within.
  ///
  /// In order to migrate the tiles to the new format, [urlTemplates] must be
  /// used. The key must be the URL as passed to `TileLayer` when
  /// the tile was stored. The value must be another map containing two
  /// [RegExp]s, the first being replaced by the second as a string, which will
  /// later be used to match the stored name.
  ///
  /// As an example, this is used to support the OpenStreetMap tile server, for
  /// which support is preset (so does not need to be specified):
  /// ```dart
  /// {
  /// 'https://tile.openstreetmap.org/{z}/{x}/{y}.png':
  ///     {RegExp('{(.*?)}'): RegExp('([0-9]+)')}
  /// }
  /// ```
  ///
  /// Recovery files and cached statistics will be lost.
  ///
  /// Returns `false` if no structure was found or migration failed, otherwise
  /// `true`.
  Future<bool> fromV6({
    List<String>? urlTemplates,
    Directory? customDirectory,
  }) async {
    // https://tile.openstreetmap.org/{z}/{x}/{y}.png
    // https___tile.openstreetmap.org_{z}_{x}_{y}.png
    // https___tile.openstreetmap.org_1_2_3.png

    // https://{s}.tile.thunderforest.com/{style}/{x}/{y}/{z}.png_apikey={apikey}
    // https___{s}.tile.thunderforest.com_{style}_{x}_{y}_{z}.png_apikey={apikey}
    // https___a.tile.thunderforest.com_outdoors_1_2_3.png_apikey=apiKey

    final Map<String, String> matchables = Map.fromEntries(
      [
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        'https://{s}.tile.thunderforest.com/{style}/{x}/{y}/{z}.png?apikey={apikey}',
        ...urlTemplates ?? [],
      ].map((url) {
        final sanitised = filesystemSanitiseValidate(
          inputString: url,
          throwIfInvalid: false,
        );
        return MapEntry(
          sanitised.replaceAll(RegExp('{(.*?)}'), '(.*?)'),
          sanitised,
        );
      }),
    );

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
    if (root == null) return false;

    await for (final tiles
        in (root >> 'stores').list().whereType<Directory>()) {
      await (tiles >> 'tiles').list().whereType<File>().asyncMap(
        (f) async {
          for (final e in matchables.entries) {
            final filename = path.basename(f.absolute.path);

            if (!RegExp('^${e.key}\$', multiLine: true).hasMatch(filename)) {
              continue;
            }

            final templateSplit = e.value.split('')..add('');
            final filenameSplit = filename.split('')..add('');

            print(templateSplit.join());
            print(filename);

            final Map<String, String> recordedValues = {};

            for (int templatePos = 0;
                templatePos < templateSplit.length;
                templatePos++) {
              final templateChar = templateSplit[templatePos];

              if (templateChar == '{') {
                int mTemplatePos = templatePos;
                final StringBuffer mTemplateValue = StringBuffer();
                while (true) {
                  final mTemplateChar = templateSplit[mTemplatePos];
                  if (mTemplateChar == '}') break;
                  if (mTemplatePos != templatePos) {
                    mTemplateValue.write(mTemplateChar);
                  }
                  mTemplatePos++;
                }

                final startPos = templatePos;
                final exitPos = templateSplit[mTemplatePos + 1];
                print(exitPos);

                final StringBuffer mFilenameValue = StringBuffer();
                int i = 0;
                while (true) {
                  if (filenameSplit[i] == exitPos || filenameSplit[i] == '')
                    break;
                  mFilenameValue.write(filenameSplit[i + startPos]);
                  i++;
                }

                recordedValues[mTemplateValue.toString()] =
                    mFilenameValue.toString();
              }
            }

            /*int posTemplate = 0;
            int posFilename = 0;
            bool recording = false;
            String recordingCacheKey = '';
            String recordingCacheValue = '';
            while (true) {
              if (posTemplate >= templateSplit.length) break;
              if (templateSplit[posTemplate] == '{') {
                recording = true;
                posTemplate++;
                continue;
              }
              if (filenameSplit[posFilename + 1] ==
                  templateSplit[posTemplate + 1]) {
                recording = false;
                recordedValues[recordingCacheKey] = recordingCacheValue;
                recordingCacheKey = '';
                recordingCacheValue = '';
                posTemplate++;
                continue;
              }
              if (recording) {
                recordingCacheKey += templateSplit[posTemplate++];
                recordingCacheValue += filenameSplit[posFilename++];
                continue;
              }

              posTemplate++;
              posFilename++;
            }*/

            print(recordedValues);
            print('------');

            /*
            final splitFilename = filename.split('')..add('');
            final matches = RegExp('{(.*?)}').allMatches(e.value);
            final matchesString =
                matches.map((m) => e.value.substring(m.start, m.end)).toList();
            //final numberMatches = RegExp('[0-9]+')
            //    .allMatches(filename)
            //    .map((m) => filename.substring(m.start, m.end))
            //    .toList();
            final extendedTemplate = e.value.split('')..add('');
            int replaceLengths = 0;

            print(e.key);
            print(e.value);
            print(matches);
            print(matchesString);
            print(filename);
            print('---');

            for (final match in matches) {
              final afterChar = extendedTemplate[match.end +
                  (replaceLengths - (replaceLengths == 0 ? 2 : -2))];
              print('00: $afterChar');

              print(match.toString());
              String val = '';
              for (int i = match.start - 2 - replaceLengths;
                  splitFilename[i] != afterChar;
                  i++) {
                // ignore: use_string_buffers
                val += splitFilename[i];
                print(val);
              }
              replaceLengths += -(match.end - match.start) + val.length;
            }

            print('---------');*/

            /*late String z;
            late String x;
            late String y;

            for (int _ = 0; _ < 3; _++) {
              if (templateMatches.last == '{z}') z = numberMatches.last;
              if (templateMatches.last == '{x}') x = numberMatches.last;
              if (templateMatches.last == '{y}') y = numberMatches.last;
              templateMatches.removeLast();
              numberMatches.removeLast();
            }

            print(z);
            print(x);
            print(y);*/

            break;
          }
        },
      ).toList();
    }
    return true;

    /*// Delete recovery files and cached statistics
    final oldRecovery = root >> 'recovery';
    if (await oldRecovery.exists()) await oldRecovery.delete(recursive: true);
    final oldStats = root >> 'stats';
    if (await oldStats.exists()) await oldStats.delete(recursive: true);

    await for (final tiles in (root >> 'tiles').list().whereType<Directory>()) {
      final store = FMTCRegistry.instance.tileDatabases[await FMTC
          .instance(p.basename(tiles.absolute.path))
          .manage
          ._advancedCreate()]!;

      await store.writeTxn(
        () async => store.tiles.putAll(
          await tiles.list().whereType<File>().asyncMap(
            (f) async {
              for (final e in matchables.entries) {
                if (!RegExp('^${e.key}\$', multiLine: true)
                    .hasMatch(p.basename(f.absolute.path))) continue;
                print(e);
              }

              return DbTile(
                x: x,
                y: y,
                z: z,
                bytes: await f.readAsBytes(),
              );
            },
          ).toList(),
        ),
      );
    }

    return true;*/
  }
}

//! OLD FILESYSTEM SANITISER CODE !//

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
      defaultFilesystemSanitiser(inputString);

  if (throwIfInvalid && output.errorMessages.isNotEmpty) {
    throw InvalidFilesystemString(
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
