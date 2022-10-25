// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../flutter_map_tile_caching.dart';
import '../internal/exts.dart';

/// Manage migration for file structure across FMTC versions
class RootMigrator {
  /// The root directory to migrate into
  final RootDirectory _rootDirectory;

  /// Manage migration for file structure across FMTC versions
  RootMigrator(this._rootDirectory);

  /// Migrates a v4 file structure to a v5 structure
  ///
  /// Checks within `getApplicationDocumentsDirectory()` and `getTemporaryDirectory()` for a directory named 'mapCache'. Alternatively, specify a custom directory to search for 'mapCache' within.
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
      await (await root.listWithExists())
          .whereType<Directory>()
          .asyncMap((e) async {
        final StoreDirectory store = StoreDirectory(
          _rootDirectory,
          p.basename(e.absolute.path),
          autoCreate: false,
        );
        await store.manage.createAsync();

        await store.access.tiles.delete();
        await e.rename(store.access.real > 'tiles');
      }).last;

      await root.delete(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
