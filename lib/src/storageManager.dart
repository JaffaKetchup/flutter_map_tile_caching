import 'dart:io';

import 'package:http/http.dart' as http;

/// Handles caching for tiles
///
/// Used internally for downloading regions, another library is depended on for browse caching
class TileStorageManager {
  /// The directory to place cache stores into. Use the same directory used in `StorageCachingTileProvider` wherever possible. Required.
  final Directory parentDirectory;

  /// The name of a store. Defaults to 'mainCache'.
  final String storeName;

  /// Create an instance to handle caching for tiles
  ///
  /// Used internally for downloading regions, another library is depended on for browse caching
  TileStorageManager(this.parentDirectory, [this.storeName = 'mainCache']);

  /// Cache a new tile given at least a URL, and optionally an HTTP client and an error handler function
  Future<void> newTile({
    required String url,
    http.Client? client,
    void Function(dynamic)? errorHandler,
  }) async {
    try {
      Directory(parentDirectory.path + '/$storeName/tiles/')
          .createSync(recursive: true);
      File(
        parentDirectory.path +
            '/$storeName/tiles/' +
            url
                .replaceAll('https://', '')
                .replaceAll('http://', '')
                .replaceAll("/", ""),
      ).writeAsBytesSync(
          (await (client ?? http.Client()).get(Uri.parse(url))).bodyBytes);
    } catch (e) {
      if (errorHandler != null) errorHandler(e);
    }
  }

  /// Delete a cached tile given a URL or a file name
  void deleteTile({
    String? url,
    String? fileName,
  }) {
    assert(
      (!(url == null && fileName == null)) ||
          (!(url != null && fileName != null)),
      'Provide one of either `url` or `fileName` to delete a tile',
    );
    final file = (url != null
        ? File(
            parentDirectory.path +
                '/$storeName/tiles/' +
                url
                    .replaceAll('https://', '')
                    .replaceAll('http://', '')
                    .replaceAll("/", ""),
          )
        : File(
            parentDirectory.path + '/$storeName/tiles/' + fileName!,
          ));
    if (file.existsSync()) file.deleteSync();
  }

  /// Delete a whole cache store
  void deleteStore() {
    if (Directory(parentDirectory.path + '/$storeName/').existsSync())
      Directory(parentDirectory.path + '/$storeName/')
          .deleteSync(recursive: true);
  }

  /// Delete all cache stores
  void clearCache() {
    if (Directory(parentDirectory.path).existsSync())
      Directory(parentDirectory.path).deleteSync(recursive: true);
  }
}
