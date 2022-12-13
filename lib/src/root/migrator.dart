// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../fmtc.dart';

/// Manage migration for file structure across FMTC versions
@internal
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
  inal Map<String, String> matchables = {
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
            final filename = p.basename(f.absolute.path);

            if (!RegExp('^${e.key}\$', multiLine: true).hasMatch(filename)) {
              continue;
            }

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
                val += splitFilename[i];
                print(val);
              }
              replaceLengths += -(match.end - match.start) + val.length;
            }

            print('---------');

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
