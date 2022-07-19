import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../internal/exts.dart';
import '../root/directory.dart';

/// Manage migration for file structure across FMTC versions
class FMTCMigrator {
  /// The root directory to migrate into
  final RootDirectory _rootDirectory;

  /// Manage migration for file structure across FMTC versions
  FMTCMigrator(this._rootDirectory);

  /// Migrates a v4 file structure to a v5 structure
  ///
  /// Checks within `getApplicationDocumentsDirectory()` and `getTemporaryDirectory()` for a directory named 'mapCache'. Alternativley, specify a custom directory to search for 'mapCache' within.
  ///
  /// Returns `false` if no structure was found or migration failed, otherwise `true`.
  Future<bool> fromV4({
    Directory? customSearch,
  }) async {
    final Directory normal =
        (await getApplicationDocumentsDirectory()) >> 'mapCache';
    final Directory temporary = (await getTemporaryDirectory()) >> 'mapCache';
    final Directory? custom =
        customSearch == null ? null : customSearch >> 'mapCache';

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

    try {
      await root.list().whereType<Directory>().asyncMap((e) async {
        print(e.path);
        print(_rootDirectory.access.stats > p.basename(e.absolute.path));
        await e.rename(
          _rootDirectory.access.stats > p.basename(e.absolute.path),
        );
      }).last;

      await root.delete(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
