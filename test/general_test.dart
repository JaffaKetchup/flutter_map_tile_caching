// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map_tile_caching/custom_backend_api.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// To install ObjectBox dependencies:
//  * use bash terminal
//  * cd to test/
//  * run `bash <(curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh) --quiet`

void main() {
  setUpAll(() {
    // Necessary to locate the ObjectBox libs
    Directory.current =
        Directory(p.join(Directory.current.absolute.path, 'test'));
  });

  group(
    'Basic store usage & root stats consistency',
    () {
      setUpAll(
        () => FMTCObjectBoxBackend().initialise(useInMemoryDatabase: true),
      );

      test(
        'Initially zero/empty',
        () async {
          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(await FMTCRoot.stats.storesAvailable, []);
        },
      );

      test(
        'Create "store1"',
        () async {
          await const FMTCStore('store1').manage.create();

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1')],
          );
        },
      );

      test(
        'Duplicate creation allowed',
        () async {
          await const FMTCStore('store1').manage.create();

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1')],
          );
        },
      );

      test(
        'Create "store2"',
        () async {
          await const FMTCStore('store2').manage.create();

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1'), const FMTCStore('store2')],
          );
        },
      );

      test(
        'Delete "store2"',
        () async {
          await const FMTCStore('store2').manage.delete();

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1')],
          );
        },
      );

      test(
        'Duplicate deletion allowed',
        () async {
          await const FMTCStore('store2').manage.delete();

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1')],
          );
        },
      );

      test(
        'Cannot reset/rename "store2"',
        () async {
          expect(
            () => const FMTCStore('store2').manage.reset(),
            throwsA(const TypeMatcher<StoreNotExists>()),
          );
          expect(
            () => const FMTCStore('store2').manage.rename('store0'),
            throwsA(const TypeMatcher<StoreNotExists>()),
          );

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1')],
          );
        },
      );

      test(
        'Reset "store1"',
        () async {
          await const FMTCStore('store1').manage.reset();

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1')],
          );
        },
      );

      test(
        'Rename "store1" to "store3"',
        () async {
          await const FMTCStore('store1').manage.rename('store3');

          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store3')],
          );
        },
      );

      tearDownAll(
        () => FMTCObjectBoxBackend()
            .uninitialise(deleteRoot: true, immediate: true),
      );
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'Metadata',
    () {
      setUpAll(() async {
        await FMTCObjectBoxBackend().initialise(useInMemoryDatabase: true);
        await const FMTCStore('store').manage.create();
      });

      test(
        'Initially empty',
        () async {
          expect(await const FMTCStore('store').metadata.read, {});
        },
      );

      test(
        'Write',
        () async {
          await const FMTCStore('store')
              .metadata
              .set(key: 'key', value: 'value');
          expect(
            await const FMTCStore('store').metadata.read,
            {'key': 'value'},
          );
        },
      );

      test(
        'Overwrite',
        () async {
          await const FMTCStore('store')
              .metadata
              .set(key: 'key', value: 'value2');
          expect(
            await const FMTCStore('store').metadata.read,
            {'key': 'value2'},
          );
        },
      );

      test(
        'Bulk (over)write',
        () async {
          await const FMTCStore('store')
              .metadata
              .setBulk(kvs: {'key': 'value3', 'key2': 'value4'});
          expect(
            await const FMTCStore('store').metadata.read,
            {'key': 'value3', 'key2': 'value4'},
          );
        },
      );

      test(
        'Remove existing',
        () async {
          expect(
            await const FMTCStore('store').metadata.remove(key: 'key2'),
            'value4',
          );
          expect(
            await const FMTCStore('store').metadata.read,
            {'key': 'value3'},
          );
        },
      );

      test(
        'Remove non-existent',
        () async {
          expect(
            await const FMTCStore('store').metadata.remove(key: 'key3'),
            null,
          );
          expect(
            await const FMTCStore('store').metadata.read,
            {'key': 'value3'},
          );
        },
      );

      test(
        'Reset',
        () async {
          await const FMTCStore('store').metadata.reset();
          expect(await const FMTCStore('store').metadata.read, {});
        },
      );

      tearDownAll(
        () => FMTCObjectBoxBackend()
            .uninitialise(deleteRoot: true, immediate: true),
      );
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'Tile operations & stats consistency',
    () {
      setUpAll(() async {
        await FMTCObjectBoxBackend().initialise(useInMemoryDatabase: true);
        await const FMTCStore('store1').manage.create();
        await const FMTCStore('store2').manage.create();
      });

      final tileA64 =
          (url: 'https://example.com/0/0/0.png', bytes: Uint8List(64));
      final tileA128 =
          (url: 'https://example.com/0/0/0.png', bytes: Uint8List(128));
      final tileB64 = (
        url: 'https://example.com/1/1/1.png',
        bytes: Uint8List.fromList(List.filled(64, 1)),
      );
      final tileB128 = (
        url: 'https://example.com/1/1/1.png',
        bytes: Uint8List.fromList(List.filled(128, 1)),
      );

      test(
        'Initially semi-zero/empty',
        () async {
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 0, size: 0, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 0, size: 0, hits: 0, misses: 0),
          );
          expect(await const FMTCStore('store1').stats.tileImage(), null);
          expect(await const FMTCStore('store2').stats.tileImage(), null);
          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(
            await FMTCRoot.stats.storesAvailable,
            [const FMTCStore('store1'), const FMTCStore('store2')],
          );
        },
      );

      test(
        'Write tile (A64) to "store1"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1'],
            writeAllNotIn: null,
            url: tileA64.url,
            bytes: tileA64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.0625);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
        },
      );

      test(
        'Write tile (A64) again to "store1"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1'],
            writeAllNotIn: null,
            url: tileA64.url,
            bytes: tileA64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.0625);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
        },
      );

      test(
        'Write tile (A128) to "store1"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1'],
            writeAllNotIn: null,
            url: tileA128.url,
            bytes: tileA128.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.125);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
        },
      );

      test(
        'Write tile (B64) to "store1"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1'],
            writeAllNotIn: null,
            url: tileB64.url,
            bytes: tileB64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 2, size: 0.1875, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.1875);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB64.bytes,
          );
        },
      );

      test(
        'Write tile (B128) to "store1"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1'],
            writeAllNotIn: null,
            url: tileB128.url,
            bytes: tileB128.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 2, size: 0.25, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.25);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB128.bytes,
          );
        },
      );

      test(
        'Write tile (B64) again to "store1"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1'],
            writeAllNotIn: null,
            url: tileB64.url,
            bytes: tileB64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 2, size: 0.1875, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.1875);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB64.bytes,
          );
        },
      );

      test(
        'Delete tile (B(64)) from "store1"',
        () async {
          await FMTCBackendAccess.internal.deleteTile(
            storeName: 'store1',
            url: tileB128.url,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.125);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
        },
      );

      test(
        'Write tile (A64) to "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store2'],
            writeAllNotIn: null,
            url: tileA64.url,
            bytes: tileA64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.0625);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
        },
      );

      test(
        'Write tile (A128) to "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store2'],
            writeAllNotIn: null,
            url: tileA128.url,
            bytes: tileA128.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.125);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
        },
      );

      test(
        'Delete tile (A(128)) from "store2"',
        () async {
          await FMTCBackendAccess.internal.deleteTile(
            storeName: 'store2',
            url: tileA128.url,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 0, size: 0, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.125);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
          expect(await const FMTCStore('store2').stats.tileImage(), null);
        },
      );

      test(
        'Write tile (B64) to "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store2'],
            writeAllNotIn: null,
            url: tileB64.url,
            bytes: tileB64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.1875);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB64.bytes,
          );
        },
      );

      test(
        'Write tile (A64) to "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store2'],
            writeAllNotIn: null,
            url: tileA64.url,
            bytes: tileA64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 2, size: 0.125, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.125);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
        },
      );

      test(
        'Reset stores',
        () async {
          await const FMTCStore('store1').manage.reset();
          await const FMTCStore('store2').manage.reset();
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 0, size: 0, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 0, size: 0, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 0);
          expect(await FMTCRoot.stats.size, 0);
          expect(await const FMTCStore('store1').stats.tileImage(), null);
          expect(await const FMTCStore('store2').stats.tileImage(), null);
        },
      );

      test(
        'Write tile (A64) to "store1" & "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1', 'store2'],
            writeAllNotIn: null,
            url: tileA64.url,
            bytes: tileA64.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 1, size: 0.0625, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.0625);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA64.bytes,
          );
        },
      );

      test(
        'Write tile (A128) to "store1" & "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1', 'store2'],
            writeAllNotIn: null,
            url: tileA128.url,
            bytes: tileA128.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 1);
          expect(await FMTCRoot.stats.size, 0.125);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileA128.bytes,
          );
        },
      );

      test(
        'Write tile (B128) to "store1" & "store2"',
        () async {
          await FMTCBackendAccess.internal.writeTile(
            storeNames: ['store1', 'store2'],
            writeAllNotIn: null,
            url: tileB128.url,
            bytes: tileB128.bytes,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 2, size: 0.25, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 2, size: 0.25, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.25);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB128.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB128.bytes,
          );
        },
      );

      test(
        'Delete tile (A(128)) from "store1"',
        () async {
          await FMTCBackendAccess.internal.deleteTile(
            storeName: 'store1',
            url: tileA128.url,
          );
          expect(
            await const FMTCStore('store1').stats.all,
            (length: 1, size: 0.125, hits: 0, misses: 0),
          );
          expect(
            await const FMTCStore('store2').stats.all,
            (length: 2, size: 0.25, hits: 0, misses: 0),
          );
          expect(await FMTCRoot.stats.length, 2);
          expect(await FMTCRoot.stats.size, 0.25);
          expect(
            ((await const FMTCStore('store1').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB128.bytes,
          );
          expect(
            ((await const FMTCStore('store2').stats.tileImage())?.image
                    as MemoryImage?)
                ?.bytes,
            tileB128.bytes,
          );
        },
      );

      tearDownAll(
        () => FMTCObjectBoxBackend()
            .uninitialise(deleteRoot: true, immediate: true),
      );
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );
}
