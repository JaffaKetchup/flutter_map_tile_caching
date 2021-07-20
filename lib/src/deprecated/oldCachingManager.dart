import 'dart:typed_data';

import 'package:flutter_map/plugin_api.dart';
import 'package:meta/meta.dart';

import '../storageManager.dart';

/// Deprecated. Will be removed in the next release. Use the newer alternative `MapCachingManager()` as soon as possible - see the API docs for documentation. The newer alternative offers much more functionality and fine grained control/information, can offer performance improvements on larger caches, and reduces this library's size (over 50% reduction in this file). All APIs inside this class have also been deprecated/moved: see deprecation warning on applicable APIs for more information.
@Deprecated(
  'This class has been deprecated, and will be removed in the next release. Use the newer alternative `MapCachingManager()` as soon as possible - see the API docs for documentation. The newer alternative offers much more functionality and fine grained control/information, can offer performance improvements on larger caches, and reduces this library\'s size (over 50% reduction in this file). All APIs inside this class have also been deprecated/moved: see deprecation warning on applicable APIs for more information.',
)
class TileStorageCachingManager {
  /// Deprecated. Functionality has been removed (calling this method will throw an error). The newer alternative has been marked as internal usage only - see the API docs for documentation.
  @Deprecated(
    'This method has been deprecated, and it\'s functionality has been removed (calling this method will throw an error). The newer alternative has been marked as internal usage only - see the API docs for documentation.',
  )
  @alwaysThrows
  static getTile(
    Coords coords, {
    String cacheName = 'mainCache',
  }) {
    throw UnsupportedError(
      'This method has been deprecated, and will be removed in the next release. The newer alternative has been marked as internal usage only - see the API docs for documentation.',
    );
  }

  /// Deprecated. Functionality has been removed (calling this method will throw an error). The newer alternative has been marked as internal usage only - see the API docs for documentation.
  @Deprecated(
    'This method has been deprecated, and it\'s functionality has been removed (calling this method will throw an error). The newer alternative has been marked as internal usage only - see the API docs for documentation.',
  )
  @alwaysThrows
  static saveTile(
    Uint8List tile,
    Coords coords, {
    String cacheName = 'mainCache',
  }) {
    throw UnsupportedError(
      'This method has been deprecated, and will be removed in the next release. The newer alternative has been marked as internal usage only - see the API docs for documentation.',
    );
  }

  /// Deprecated. Functionality has been removed (calling this getter will throw an error). Migrate to `StorageCachingTileProvider().maxStoreLength`.
  @Deprecated(
    'This getter has been deprecated, and it\'s functionality has been removed (calling this getter will throw an error). Migrate to `StorageCachingTileProvider().maxStoreLength`.',
  )
  @alwaysThrows
  static changeMaxTileAmount(
    int maxTileAmount,
  ) {
    throw UnsupportedError(
      'This method has been deprecated, and will be removed in the next release. Migrate to `StorageCachingTileProvider().',
    );
  }

  /// Deprecated. Will be removed in the next release. Migrate to `MapCachingManager().deleteAllStores()`.
  @Deprecated(
    'This method has been deprecated, and will be removed in the next release. Migrate to `MapCachingManager().deleteAllStores()`.',
  )
  static Future<void> cleanAllCache() async {
    MapCachingManager(await MapCachingManager.normalDirectory)
        .deleteAllStores();
  }

  /// Deprecated. Will be removed in the next release. Migrate to `MapCachingManager().deleteStore()`.
  @Deprecated(
    'This method has been deprecated, and will be removed in the next release. Migrate to `MapCachingManager().deleteStore()`.',
  )
  static Future<int> cleanCacheName([String cacheName = 'mainCache']) async {
    MapCachingManager(await MapCachingManager.normalDirectory, cacheName)
        .deleteStore();
    return -1;
  }

  /// Deprecated. Functionality has been removed (calling this getter will throw an error). There is no newer alternative.
  @Deprecated(
    'This getter has been deprecated, and it\'s functionality has been removed (calling this getter will throw an error). There is no newer alternative.',
  )
  @alwaysThrows
  static get dbFile async {
    throw UnsupportedError(
      'This getter has been deprecated, and will be removed in the next release. There is no newer alternative.',
    );
  }

  /// Deprecated. Functionality has been removed (calling this getter will throw an error). There is no newer alternative.
  @Deprecated(
    'This getter has been deprecated, and it\'s functionality has been removed (calling this getter will throw an error). There is no newer alternative.',
  )
  @alwaysThrows
  static get isDbFileExists async {
    throw UnsupportedError(
      'This getter has been deprecated, and will be removed in the next release. There is no newer alternative.',
    );
  }

  /// Deprecated. Will be removed in the next release. Migrate to `MapCachingManager().allStoresSize`.
  @Deprecated(
    'This getter has been deprecated, and will be removed in the next release. Migrate to `MapCachingManager().allStoresSize`.',
  )
  static Future<int> get cacheDbSize async {
    return MapCachingManager(await MapCachingManager.normalDirectory)
            .allStoresSize ??
        0;
  }

  /// Deprecated. Will be removed in the next release. Migrate to `MapCachingManager().allStoresLength`.
  @Deprecated(
    'This getter has been deprecated, and will be removed in the next release. Migrate to `MapCachingManager().allStoresLength`.',
  )
  static Future<int> get cachedTilesAmount async {
    return MapCachingManager(await MapCachingManager.normalDirectory)
            .allStoresLength ??
        0;
  }

  /// Deprecated. Will be removed in the next release. Migrate to `MapCachingManager().storeLength`.
  @Deprecated(
    'This method has been deprecated, and will be removed in the next release. Migrate to `MapCachingManager().storeLength`.',
  )
  static Future<int> cachedTilesAmountName(String cacheName) async {
    return MapCachingManager(await MapCachingManager.normalDirectory, cacheName)
            .storeLength ??
        0;
  }

  /// Deprecated. Will be removed in the next release. Migrate to `MapCachingManager().allStoresNames`.
  @Deprecated(
    'This getter has been deprecated, and will be removed in the next release. Migrate to `MapCachingManager().allStoresNames`.',
  )
  static Future<List<String>> get allCacheNames async {
    return MapCachingManager(await MapCachingManager.normalDirectory)
            .allStoresNames ??
        [];
  }

  /// Deprecated. Functionality has been removed (calling this getter will always return 20000). Migrate to `StorageCachingTileProvider().maxStoreLength`.
  @Deprecated(
    'This getter has been deprecated, and it\'s functionality has been removed (calling this getter will always return 20000). Migrate to `StorageCachingTileProvider().maxStoreLength`.',
  )
  static Future<int> get maxCachedTilesAmount async {
    return 20000;
  }
}
