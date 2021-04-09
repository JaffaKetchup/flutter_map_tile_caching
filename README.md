# flutter_map_tile_caching

A plugin for the `flutter_map` library. Adds full tile caching functionality and methods to download areas of tiles.

## Example

To view the example, copy the `main.dart` file inside the `example` directory, and run it inside your own new project. You shouldn't need to add any extra dependencies except this package (see below).

## Installation

To install this plugin, add the below code snippet to your `pubspec.yaml` file.

```dart
    flutter_map_tile_caching: ^1.0.1
```

## Usage

### New Tile Provider

This plugin adds the new tile provider: `StorageCachingTileProvider(...)`.
This takes the optional `cachedValidDuration` `Duration` argument which defaults to a duration of 1 day.

When new tiles are loaded, this tile provider will cache them in a database cache.  When these tiles are requested again, the tile will be taken from cache if it is younger than it's `cachedValidDuration`, otherwise the tile will be requested again. However, if the request fails (eg. there is no Internet connection), the tile should still be taken from cache.

### New Classes, Methods & Functions

This plugin adds the new classes: `StorageCachingTileProvider` & `TileStorageCachingManager`.

#### `StorageCachingTileProvider`

You can call `loadTiles(...)` on `StorageCachingTileProvider(...)`, and pass in the appropriate bounds and min/max zoom levels. This will download and precache all the tiles in the specified area for all the specified zoom levels. It can be listened to for a `Tuple3<int, int, int>`, with the number of downloaded tiles, number of errored tiles (eg. tiles that couldn't be downloaded due to lack of Internet connection), and the total number of tiles to be downloaded, in that order. A maximum of 10000 tiles can be downloaded at once, or the `maxCachedTilesAmount` in total, whichever comes first. You can see an example of this in the example file.

You can call `approximateTileAmount(...)` on `StorageCachingTileProvider`, and pass in the appropriate bounds and min/max zoom levels. This will return an `int` which is the approximate number of tiles within the specified area.

#### `TileStorageCachingManager`

You can call `cacheDbSize` on `TileStorageCachingManager`. This will return a `Future<int>` which is the size of the caching database in bytes. Divide by 1024 then by 1024 to get the number of megabytes.

You can call `cachedTilesAmount` on `TileStorageCachingManager`. This will return a `Future<int>` which is the total number of tiles currently cached.

You can call `maxCachedTilesAmount` on `TileStorageCachingManager`. This will return a `Future<int>` which is the maximum number of tiles allowed to be cached at any one time.

You can call `kDefaultMaxTileAmount` on `TileStorageCachingManager`. This will return an `int` which is the default maximum number of tiles allowed to be cached at any one time. This might differ to `maxCachedTilesAmount` if `changeMaxTileAmount(...)` has ever been called.

You can call `changeMaxTileAmount(...)` on `TileStorageCachingManager`, and pass in the new max tile amount to change `maxCachedTilesAmount`.

You can call `cleanCache()` on `TileStorageCachingManager`. This will clear all the cached tiles from the database forever, without warning.

## Limitations

This package currently uses `flutter_map: ^0.12.0`, and is therefore not null-safe. It does not support the web platform (due to the usage of `dart:io`), and the code has not been tested on desktop platforms.

## Credits

This code was originally created by [bugDim88](https://github.com/bugDim88), and improved upon by multiple people. You can see the original pull request here: [pull request #564 on fleaflet/flutter_map](https://github.com/fleaflet/flutter_map/pull/564). JaffaKetchup seperated the code into this external package on behalf of [bugDim88](https://github.com/bugDim88) & other contributors to keep the base package small. All credit therefore goes to [bugDim88](https://github.com/bugDim88) and the other contributors.
