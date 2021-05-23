# flutter_map_tile_caching

>## Branch 'v3-testing'
>
>Please note, you are currently not in the 'main' branch, which is the branch that is kept production ready. This branch is only currently for development, and should not be used except for development or testing.

A plugin for the [`flutter_map`](https://pub.dev/packages/flutter_map) library. Adds full tile caching functionality and methods to download areas of tiles.

[![Pub](https://img.shields.io/pub/v/flutter_map_tile_caching.svg)](https://pub.dev/packages/flutter_map_tile_caching) [![likes](https://badges.bar/flutter_map_tile_caching/likes)](https://pub.dev/packages/flutter_map_tile_caching/score) [![pub points](https://badges.bar/flutter_map_tile_caching/pub%20points)](https://pub.dev/packages/flutter_map_tile_caching/score)
[![GitHub stars](https://img.shields.io/github/stars/JaffaKetchup/flutter_map_tile_caching.svg?style=social&label=Stars)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/stargazers/) [![GitHub issues](https://img.shields.io/github/issues/JaffaKetchup/flutter_map_tile_caching.svg?style=social&label=Issues)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/issues/) [![GitHub PRs](https://img.shields.io/github/issues-pr/JaffaKetchup/flutter_map_tile_caching.svg?style=social&label=Pull%20Requests)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/pulls/)

## Example

To view the example, copy the `main.dart` file inside the `example` directory, and run it inside your own new project. You'll need to add this package (see below) and `flutter_map` to your dependencies.

## Installation

To install this plugin, add the below code snippet to your `pubspec.yaml` file:

```yaml
    flutter_map_tile_caching:
```

followed by `^`, then the most recent available pub.dev version (without the 'v') (currently [![Pub](https://img.shields.io/pub/v/flutter_map_tile_caching.svg)](https://pub.dev/packages/flutter_map_tile_caching)).
If you urgently need the most recent version of this package that hasn't been published to pub.dev yet, use this code snippet instead (please note that this method is not recommended):

```yaml
    flutter_map_tile_caching:
        git:
            url: https://github.com/JaffaKetchup/flutter_map_tile_caching
```

## Usage

Use it like any other package. You'll have access to all the things listed below.

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```

### New Tile Provider

This plugin adds the new tile provider: `StorageCachingTileProvider(...)`.
This takes the optional `cachedValidDuration` `Duration` argument which defaults to a duration of 31 days.

When new tiles are loaded, this tile provider will cache them in a database cache.  When these tiles are requested again, the tile will be taken from cache if it is younger than it's `cachedValidDuration`, otherwise the tile will be requested again. However, if the request fails (eg. there is no Internet connection), the tile should still be taken from cache.

### New Classes, Methods & Functions

This plugin adds the new classes: `StorageCachingTileProvider` & `TileStorageCachingManager`.

#### `StorageCachingTileProvider`

You can call `loadTiles(...)` on `StorageCachingTileProvider(...)`, and pass in the appropriate bounds and min/max zoom levels. This will download and precache all the tiles in the specified area for all the specified zoom levels. It can be listened to for a `Tuple3<int, int, int>`, with the number of downloaded tiles, number of errored tiles (eg. tiles that couldn't be downloaded due to lack of Internet connection), and the total number of tiles to be downloaded, in that order. The `maxCachedTilesAmount` can be cached at once, which defaults to 20000.

You can call `approximateTileAmount(...)` on `StorageCachingTileProvider`, and pass in the appropriate bounds and min/max zoom levels. This will return an `int` which is the approximate number of tiles within the specified area.

#### `TileStorageCachingManager`

You can call `cacheDbSize` on `TileStorageCachingManager`. This will return a `Future<int>` which is the size of the caching database in bytes. Divide by 1049000 to get the number of megabytes.

You can call `cachedTilesAmount` on `TileStorageCachingManager`. This will return a `Future<int>` which is the total number of tiles currently cached.

You can call `maxCachedTilesAmount` on `TileStorageCachingManager`. This will return a `Future<int>` which is the maximum number of tiles allowed to be cached at any one time.

You can call `kDefaultMaxTileAmount` on `TileStorageCachingManager`. This will return an `int` which is the default maximum number of tiles allowed to be cached at any one time. This might differ to `maxCachedTilesAmount` if `changeMaxTileAmount(...)` has ever been called.

You can call `changeMaxTileAmount(...)` on `TileStorageCachingManager`, and pass in the new max tile amount to change `maxCachedTilesAmount`.

You can call `cleanCache()` on `TileStorageCachingManager`. This will clear all the cached tiles from the database forever, without warning.

## Limitations

This package does not support the web platform (due to the usage of `dart:io`) and the code has not been tested on desktop platforms.

## Credits

This code was originally created by [bugDim88](https://github.com/bugDim88), and improved upon by multiple people. You can see the original pull request here: [pull request #564 on fleaflet/flutter_map](https://github.com/fleaflet/flutter_map/pull/564). JaffaKetchup seperated the code into this external package on behalf of [bugDim88](https://github.com/bugDim88) & other contributors to keep the base package small. All credit therefore goes to [bugDim88](https://github.com/bugDim88) and the other contributors.

If this package is beneficial to you, please leave a star on GitHub and a like on pub.dev!
