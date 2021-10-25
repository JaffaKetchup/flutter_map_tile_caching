# flutter_map_tile_caching

A plugin for the [`flutter_map`](https://pub.dev/packages/flutter_map) providing advanced caching functionality, with ability to download map regions for offline use. Also includes useful prebuilt widgets.

[![Pub](https://img.shields.io/pub/v/flutter_map_tile_caching.svg)](https://pub.dev/packages/flutter_map_tile_caching) [![likes](https://badges.bar/flutter_map_tile_caching/likes)](https://pub.dev/packages/flutter_map_tile_caching/score) [![pub points](https://badges.bar/flutter_map_tile_caching/pub%20points)](https://pub.dev/packages/flutter_map_tile_caching/score)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[![GitHub stars](https://img.shields.io/github/stars/JaffaKetchup/flutter_map_tile_caching.svg?label=Stars)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/stargazers/) [![GitHub issues](https://img.shields.io/github/issues/JaffaKetchup/flutter_map_tile_caching.svg?label=Issues)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/issues/) [![GitHub PRs](https://img.shields.io/github/issues-pr/JaffaKetchup/flutter_map_tile_caching.svg?label=Pull%20Requests)](https://GitHub.com/JaffaKetchup/flutter_map_tile_caching/pulls/)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N151INN)

## Installation

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

After installing the package, import it into the necessary files in your project:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```

Before using any functionality, in particular the bulk downloading functionality, make sure you comply with the appropriate rules and ToS for your server. Some servers ban bulk downloading.

### Android

A few more steps are required on Android due to the background download functionality, unfortunately even if you do not intend to use the functionality. This is due to the way the dependency used to perform background downloading works.

For these steps please go to these sites:

- [`background_fetch` Installation Instructions For Android](https://github.com/transistorsoft/flutter_background_fetch/blob/master/help/INSTALL-ANDROID.md)
- [`permission_handler` Installation Instructions](https://pub.dev/packages/permission_handler#setup)

### iOS

A few more steps are required on iOS due to the background download functionality, even though this functionality is unfortunately currently blocked on iOS. This is due to the way the dependency used to perform background downloading works.
For these steps please go to these sites:

- [`background_fetch` Installation Instructions For iOS](https://github.com/transistorsoft/flutter_background_fetch/blob/master/help/INSTALL-IOS.md)  
You should not need to follow the instructions for `BackgroundFetch.scheduleTask`, but do so if you receive build errors - the custom task identifiers asked for in the last step is exactly 'backgroundTileDownload'.
- [`permission_handler` Installation Instructions](https://pub.dev/packages/permission_handler#setup)

Please note that this library has not been tested on iOS devices, so issues may arise. Please leave an issue if they do, and I'll try my best to debug and solve them.

## Example

To run the example project, create a new project and copy/replace the existing 'main.dart' file with the 'main.dart' file from this project's example folder. Remember to complete the TODOs at the top of the file. Finally, follow the platform-specific installation instructions above to get your app to build successfully.

Alternatively, if you just want to see how it works quickly, you can run the example app on an Android device by installing the APK file found in the 'example' directory. Doing this, you must comply to the [Open Street Map Tile Server rules](https://operations.osmfoundation.org/policies/tiles), specifically the section about [Bulk Downloads](https://operations.osmfoundation.org/policies/tiles/#:~:text=above%20technical%20requirements.-,Bulk%20Downloading,-Bulk%20downloading%20is). In short, don't bulk download over 250 tiles at zoom level 13 or more.

## Functionality & Terminology

This package provides every thing you should need to implement advanced caching in your Flutter application, including caching tiles as your users browse the map & downloading regions of a map for later offline use. You can reuse UI components from the example, or create your own!

This terminology appears throughout documentation:

- A 'cache' contains multiple 'stores'. There's usually only one cache per device, but there can be many stores.
- A 'region' is an area of a map.
- 'Browse caching' is the caching performed when a user pans over a tile in the map view and it becomes visible. This is automatic.
- 'Bulk downloading' is the caching performed when a user initiates a download by specifying a region to download at once. This action is banned by some servers, make sure you comply with the appropriate rules and ToS for your server.

## [API Details](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html)

Because of the many parts to this package and the small number of maintainers (only me), there is no full documentation for everything in this README or in any wiki.

Documentation has been written into the source code: you can see every class, method, extension and enumerable in the [auto generated docs (dartdoc)](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html). This lists all of the publicly available API methods and how to use them. Information visible here is also visible whilst writing code, so you should rarely need to leave the comfort of your editor.

However, for beginners some information is provided below, enough to get you to understand the gist of it, and you can find how to actually code it in the example.

### `StorageCachingTileProvider()`

The tile provider and the 'frontend' of the operation.

Integrates with `flutter_map` by registering as a tile provider that also caches tiles as users browse over them. Contains all of the functions needed to start and stop bulk downloads.

### `MapCachingManager()`

The 'backend' of the operation.

Handles the filesystem interactions, allowing you to easily find all the possible information you could ever want about a cache or store.

### The Regions

These objects define a region (I'm sure that surprised you!).

Currently, rectangular and circular regions are available, with limited support for line-based regions (which is expected to improve in the future).

As well as being used for starting a bulk download, they also contain functionality to paint the shape onto the map. Paired with tap receivers on the map widget, this means it's easy for a user to choose a region to download.

## Background Bulk Downloading

Instead of downloading in the foreground, there is an option on Android to start a download in the background.

Both foreground and background downloading are handled in separate Isolates to ensure your app performs correctly, however background downloading has some advantages, including:

- Being more reliable for large downloads
- Posting push notifications to keep the user updated outside of the app
- Guarantee* that the download will keep running outside of the app and when locked

Frontend downloading might also work outside of the app and when locked, but it's better practise to use a dedicated, registered background process.

The background download functionality has been disabled on platforms other than Android, because of the tight restrictions of other OSs, in particular Apple/iOS.

To have full background functionality including not being throttled by the system and being guaranteed to run even if the app is 'minimized', request the ignore battery optimizations permission by calling `requestIgnoreBatteryOptimizations()` before starting a background task. This will display a system interruption prompt to the user to allow or deny the permission. The background task will still run if the permission is denied, but the process is at the mercy of the system.

## Migrate to v4 from v3

Unfortunately, because so much has changed, the best way to migrate is to rewrite the appropriate areas of your project with the new features.
I've tried to make v4 even easier to understand and use, even with all the new functionality, so I hope you don't find this too time consuming.

## Limitations, Known Bugs & Testing

- This package does not support the web platform. A fix for this is unlikely to appear because the web platform is ill-suited for caching anyway.
- The region functions get less accurate the larger the region. In particular the circle region can be quite bad at large sizes: to prevent interruptive errors, the values of the calculation have been clamped to a valid minimum and maximum, but this causes side effects. To prevent unwanted results, try to use small regions, no larger than the size of Europe.
- Apps may become unstable if large numbers of tiles have been downloaded. Try to keep the amount of downloaded tiles below 50,000.
- This package has only been physically tested on one Android device, with automated tests being run regularly. However, due to the large amounts of functionality, each with many different variations, it is nearly impossible to find many bugs. Therefore, if you find a bug, please do file an Issue on GitHub, and I will do my very best to get it fixed quickly.

## Supporting Me

A donation through my Ko-Fi page would be infinitely appreciated (Ko-fi doesn't take a fee, so all donated money goes to me):  
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N151INN)  
but, if you can't or won't, a star on GitHub and a like on pub.dev would also go a long way!

Every donation/star/like gives me mental fuel to continue my open-source projects and lets me know that I'm doing a good job.

## Credits

The basis of this library was originally coded by [bugDim88](https://github.com/bugDim88), and improved upon by multiple people. You can see the original pull request here: [pull request #564 on fleaflet/flutter_map](https://github.com/fleaflet/flutter_map/pull/564).
