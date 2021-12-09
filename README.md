# flutter_map_tile_caching

A plugin for the [`flutter_map`](https://pub.dev/packages/flutter_map) library to provide an easy way to cache tiles and download map regions for offline use.

[![Pub](https://img.shields.io/pub/v/flutter_map_tile_caching.svg)](https://pub.dev/packages/flutter_map_tile_caching) [![likes](https://badges.bar/flutter_map_tile_caching/likes)](https://pub.dev/packages/flutter_map_tile_caching/score) [![pub points](https://badges.bar/flutter_map_tile_caching/pub%20points)](https://pub.dev/packages/flutter_map_tile_caching/score)
[![GitHub stars](https://img.shields.io/github/stars/JaffaKetchup/flutter_map_tile_caching.svg?style=social&label=Stars)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/stargazers/) [![GitHub issues](https://img.shields.io/github/issues/JaffaKetchup/flutter_map_tile_caching.svg?style=social&label=Issues)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/issues/) [![GitHub PRs](https://img.shields.io/github/issues-pr/JaffaKetchup/flutter_map_tile_caching.svg?style=social&label=Pull%20Requests)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/pulls/)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N151INN)

## Installation

> It is now recommended to use the v4 development version instead of the latest main version, due to significant developments/improvements and breaking changes.  
> Where possible (ie. except in production ready versions of your app), use the pre-releases of [v4](https://github.com/JaffaKetchup/flutter_map_tile_caching/tree/v4).

To install this plugin, use the normal installation method:

```shell
   > flutter pub add flutter_map_tile_caching
```

If you urgently need the most recent version of this package that hasn't been published to pub.dev yet, use this code snippet instead in your pubspec.yaml (please note that this method is not recommended):

```yaml
    flutter_map_tile_caching:
        git:
            url: https://github.com/JaffaKetchup/flutter_map_tile_caching
```

After installing the package, import it into the neccessary files in your project:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```

### Android

A few more steps are required on Android due to the background download functionality, unfortunately even if you do not intend to use the functionality. This is due to the way the dependency used to perform background downloading works.
For these steps please go here: [background_fetch Installation Instructions For Android](https://github.com/transistorsoft/flutter_background_fetch/blob/master/help/INSTALL-ANDROID.md).

### iOS

A few more steps are required on iOS due to the background download functionality, even though this functionality is unfortunately currently blocked on iOS. This is due to the way the dependency used to perform background downloading works.
For these steps please go here: [background_fetch Installation Instructions For iOS](https://github.com/transistorsoft/flutter_background_fetch/blob/master/help/INSTALL-IOS.md).
You should not need to follow the instructions for `BackgroundFetch.scheduleTask`, but do so if you recieve build errors - the custom task identifiers asked for in the last step is exactly 'backgroundTileDownload'.
Please note that this library has not been tested on iOS devices, so issues may arize. Please leave an issue if they do, and I'll try my best to debug and solve them.

## Example

To view the example project, create a new project and copy/replace the existing 'main.dart' file with the 'main.dart' file from this project's example folder. Then add this library to the 'pubspec.yaml' file. Finally, follow the platform-specific installation instructions above to get your app to build successfully.

Alternatively, if you just want to see how it works quickly, you can run the example app on an Android device by installing the APK file found in the 'example' directory. Note, however, that this file may be a few versions old.

## Functionality

This library provides 3 main functionalities and 4 main APIs:

- Automatic Tile Caching (`TileProvider` API & Caches API)
- Region Downloading (`TileProvider` API, Regions API, Downloading API & Caches API)
  - Easy Shape Chooser (Regions API)

These all work together to give you all you need to implement fully offline maps in your Flutter app.

## [API Details](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html)

You can see every class, method, extension and enumerable in the [Dart auto generated docs (dartdoc)](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html). This contains everything available and a description on how to use them. You can also check the example for how all of these things fit together. However, for simplicity for new users to this project, the main/most useful/most common parts are below, and these can be looked up in the docs using the search functionality:

#### `StorageCachingTileProvider()`

Use this as the tile provider for your `FlutterMap()` to automatically cache tiles as your users pan (aka. browse) over them. Use the same 'instance' throughout your script to avoid duplicate conflicts.
Read more about the caching behaviour below.

#### `downloadRegion()` and it's background counterpart

Use this to download large areas of a map before the user visits somewhere (for example before a hike in the wilderness).
A region can currently be a rectangular region or a circular region. More types are planned for the future.
Read more about the caching behaviour below.

#### Easy Shape Chooser

Use this as a 'layer' on your map to allow the user an easy way to select an area for downloading. Use the same 'instance' throughout your script to avoid duplicate conflicts.
A region can currently be a rectangular region or a circular region. More types are planned for the future.
This will be worked on in the future to bring better functionality.

### Migrate to v3 from v2

Unfortunately, because so much has changed, the best way to migrate is to rewrite the appropriate areas of your project with the new features.
I've tried to make v3 super easy to understand and use, even with all the new functionality, so I hope you don't find this too hard. Unfortunatley, the next major release may also require a large migration, as this library 'fully matures'.

## Offline/Caching Behaviour

Because this is an offline first package, it may act a little differently to how you expect. Both areas that interact with caching are detailed below:

### Whilst Browsing

'Browsing' in this library means panning, zooming and rotating through the map.

When a new tile is browsed, and the user is online, the tile will be fetched from the server and cached with a record of when it's expiry date is (dictated by the `cachedValidDuration` on the tile provider).
If this tile is browsed again, and the user is online, the tile will still be taken from cache, even if the user is online, unless the tile has expired, in which case it will be refetched and cached again. This is known as 'cache-first' caching.
If this tile is browsed again, but the user is not online, the tile will be taken from cache, even if the tile has expired. The network request will still be made, however, and it will fail silently.
If the user is not online, and the tile has not been cached yet, the request will fail with an error to the console, but the app will carry on working as normal.

### When Downloading Regions

Whilst using the `downloadRegion()` function (or it's background counterpart (see below)), every tile in the region will always be cached, even if the tile has been cached before but it hasn't expired.
Every tile downloaded will then act like it has been browsed (see above).

## Background Region Downloading

Instead of downloading in the foreground (on the main thread), there is an option on Android to start a download in the background.

This has several major advantages including better core app performace, ability to continue whilst the user is interacting with other app components, and (potential) ability to continue even whilst the user is in other apps or the device is locked.

The background download functionality is buggy and does not function as expected all the time on platforms other than Android, so that functionality has been disabled on all platforms except Android. This might change in the future, but there is no gurantee.

To have full background functionality including not being throttled by the system and being guaranteed to run even if the app is 'minimized', request the ignore battery optimizations permission by calling `requestIgnoreBatteryOptimizations()` before starting a background task. This will display a system interruption prompt to the user to allow or deny the permission. The background task will still run if the permission is denied, but only if the user is in the app - elsewhere, downloading is not guaranteed to be running.

## Limitations, Known Bugs & Testing

- This package does not support the web platform (due to the usage of `dart:io` and the `sqflite` package). A fix for this may appear in the future.

- Support may be buggy for custom tile sizes (other than 256x256) or custom CRSs (other than `Epsg3857()`), but attempts have been made at making this library compatible with those using inbuilt functionality from `flutter_map`. Further testing for compatibility will continue in the v4.0.0 release.

- Using `TileStorageCachingManager.changeMaxTileAmount()` will unfortunately not change the assertions in the tile provider/downloader. Until v4.0.0, the maximum number of downloadable tiles at once is 20000. This will be fixed by v4.0.0, as this release will include other refactorings.

- The circle region functions get less accurate the larger the radius of the circle. To prevent interruptive errors, the values of the calculation have been clamped to a valid minimum and maximum, but this causes side effects. To prevent these side effects, only use circles smaller than the average size of a European country, and be cautious when using circles around extremes (the equator, the longitudes of 180 or -180, and the latiudes of -90 or 90). If selecting a large region or working around the aformentioned extremes, use rectangular regions instead. A fix for this may appear in the future.

This package has only been tested on Android devices (one real Android 8, one Android 8 emulator, and one Android 11 emulator). However, due to the large amounts of functionality, each with many different variations, it is nearly impossible to find many bugs. Therefore, if you find a bug, please do file an Issue on GitHub, and I will do my very best to get it fixed quickly.

## Supporting Me

A donation through my Ko-Fi page would be infinitly appriciated:
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N151INN)

but, if you can't or won't, a star on GitHub and a like on pub.dev would also go a long way!

Every donation gives me fuel to continue my open-source projects and lets me know that I'm doing a good job.

## Credits

The basis of this library was originally coded by [bugDim88](https://github.com/bugDim88), and improved upon by multiple people. You can see the original pull request here: [pull request #564 on fleaflet/flutter_map](https://github.com/fleaflet/flutter_map/pull/564).

Since v2 here, other contributors have also been involved, who can be seen in GitHub. The only old part remaining that that coder coded is the database manager script (with all the SQL in it), but the aforementioned main coder still inspired the rest of this project and is therefore the 'founder'. Thanks to you, bugDim88!
