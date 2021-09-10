import 'dart:io';
import 'package:test/test.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() {
  Future<Directory> reset([bool dontReset = false]) async {
    final cacheDir = await MapCachingManager.normalCache;
    if (!dontReset && cacheDir.existsSync())
      try {
        cacheDir.deleteSync(recursive: true);
      } catch (e) {}
    return cacheDir;
  }

  test('Properties start empty', () async {
    final Directory parentDirectory = await reset();
    final MapCachingManager mainManager = MapCachingManager(parentDirectory);
    final MapCachingManager secondaryManager =
        MapCachingManager(parentDirectory, 'secondaryStore');

    expect(mainManager.allStoresLengths, null);
    expect(mainManager.allStoresNames, null);
    expect(mainManager.allStoresSizes, null);

    expect(mainManager.storeLength, null);
    expect(mainManager.storeSize, null);
    expect(mainManager.storeName, 'mainStore');

    expect(secondaryManager.storeLength, null);
    expect(secondaryManager.storeSize, null);
    expect(secondaryManager.storeName, 'secondaryStore');

    mainManager.createStore();
    secondaryManager.createStore();

    expect(mainManager.allStoresLengths, 0);
    expect(mainManager.allStoresNames, ['mainStore', 'secondaryStore']);
    expect(mainManager.allStoresSizes, 0);

    expect(mainManager.storeLength, 0);
    expect(mainManager.storeSize, 0);
    expect(mainManager.storeName, 'mainStore');

    expect(secondaryManager.storeLength, 0);
    expect(secondaryManager.storeSize, 0);
    expect(secondaryManager.storeName, 'secondaryStore');
  });

  test('renameStore()', () async {
    final Directory parentDirectory = await reset();
    MapCachingManager mainManager = MapCachingManager(parentDirectory)
      ..createStore();
    MapCachingManager secondaryManager =
        MapCachingManager(parentDirectory, 'secondaryStore')..createStore();

    expect(mainManager.storeName, 'mainStore');
    expect(secondaryManager.storeName, 'secondaryStore');

    mainManager = mainManager.renameStore('renamedMainStore')!;

    expect(mainManager.storeName, 'renamedMainStore');
    expect(secondaryManager.storeName, 'secondaryStore');

    secondaryManager = secondaryManager.renameStore('renamedSecondaryStore')!;

    expect(mainManager.storeName, 'renamedMainStore');
    expect(secondaryManager.storeName, 'renamedSecondaryStore');

    mainManager = mainManager.renameStore('mainStore')!;
    secondaryManager = secondaryManager.renameStore('secondaryStore')!;

    expect(mainManager.storeName, 'mainStore');
    expect(secondaryManager.storeName, 'secondaryStore');
  });

  test('deleteStore() & deleteAllStores()', () async {
    final Directory parentDirectory = await reset();
    MapCachingManager mainManager = MapCachingManager(parentDirectory)
      ..createStore();
    MapCachingManager secondaryManager =
        MapCachingManager(parentDirectory, 'secondaryStore')..createStore();

    expect(mainManager.storeLength, 0);
    expect(secondaryManager.storeLength, 0);

    mainManager.deleteStore();

    expect(mainManager.storeLength, null);
    expect(secondaryManager.storeLength, 0);

    secondaryManager.deleteStore();

    expect(mainManager.storeLength, null);
    expect(secondaryManager.storeLength, null);

    mainManager.createStore();
    secondaryManager.createStore();

    expect(mainManager.storeLength, 0);
    expect(secondaryManager.storeLength, 0);

    mainManager.deleteAllStores();

    expect(mainManager.storeLength, null);
    expect(secondaryManager.storeLength, null);
  });

  test('Use of temporaryDirectory', () async {
    final parentDirectory = await MapCachingManager.normalCache;
    if (parentDirectory.existsSync())
      parentDirectory.deleteSync(recursive: true);

    final MapCachingManager mainManager = MapCachingManager(parentDirectory);

    expect(mainManager.allStoresLengths, null);
    expect(mainManager.allStoresNames, null);
    expect(mainManager.allStoresSizes, null);

    expect(mainManager.storeLength, null);
    expect(mainManager.storeSize, null);
    expect(mainManager.storeName, 'mainStore');

    mainManager.createStore();

    expect(mainManager.allStoresLengths, 0);
    expect(mainManager.allStoresNames, ['mainStore']);
    expect(mainManager.allStoresSizes, 0);

    expect(mainManager.storeLength, 0);
    expect(mainManager.storeSize, 0);
    expect(mainManager.storeName, 'mainStore');

    mainManager.deleteAllStores();

    expect(mainManager.allStoresLengths, null);
    expect(mainManager.allStoresNames, null);
    expect(mainManager.allStoresSizes, null);
  });
}
