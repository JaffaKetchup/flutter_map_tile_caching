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
  - If you plan to use background downloading functionality and you want to request to ignore battery optimizations, you should add this to your 'android/app/src/.../AndroidManifest.xml' as seen in the example app:  
  
    ``` xml
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
    ```

### iOS

A few more steps are required on iOS due to the background download functionality, even though this functionality is unfortunately currently disabled on iOS. This is due to the way the dependency used to perform background downloading works.
For these steps please go to these sites:

- [`background_fetch` Installation Instructions For iOS](https://github.com/transistorsoft/flutter_background_fetch/blob/master/help/INSTALL-IOS.md)  
You should not need to follow the instructions for `BackgroundFetch.scheduleTask`, but do so if you receive build errors - the custom task identifiers asked for in the last step is exactly 'backgroundTileDownload'.
- [`permission_handler` Installation Instructions](https://pub.dev/packages/permission_handler#setup)

Please note that this library has not been tested on iOS devices, so issues may arise. Please leave an issue if they do, and I'll try my best to debug and solve them.

## Example

As of v4, this package contains a full example application showcasing most of the features of this package. Simply clone the this project, enter the 'example' directory, and then build for your desired platform:

- Android & Windows users should run 'androidBuilder.bat'
- Android & Linux/MacOS users should run 'androidBuilder.sh' (bash)

... to build the smallest output .apk files possible (< 14MB).  
There is no build automation for iOS devices: users will need to build manually as usual.

By using the example application, you must comply to your tile server's ToS. OpenStreetMap's (the default throughout the application) can be [found here](https://operations.osmfoundation.org/policies/tiles). If you cannot comply to these rules, you should find one that you can comply to and get the appropriate source URL (which can be customised in the application).  
Some safeguards have been built in to protect servers - specifically in the bulk download screen. You can read more about these by tapping the help icon in the app bar on that page.

Feel free to use the example app as a starting point for your application. Many screens should fit into any app - perhaps with some restyling to fit your app.

## Functionality

This package provides every thing you should need to implement advanced caching in your Flutter application, including caching tiles as your users browse the map & bulk downloading regions of a map for later offline use.

This terminology appears throughout documentation:

- A 'cache' contains multiple 'stores'. There's usually only one cache per device, but there can be many stores.
  - A cache is referred to as the `parentDirectory` throughout the API as well. Getting the directory will be an asynchronous process, so it is likely a `FutureBuilder` will be needed.
  - A store is sometimes referred to as a 'cache store', but this is just for extra clarification.
- A 'region' is an area of a map formed by particular rules ('shapes') and coordinates.
- 'Browse caching' is the caching performed when a user pans over a tile in the map view and it becomes visible.
  - If not otherwise specified, this is also usually referred to as just 'caching'.
- 'Bulk downloading' is the caching performed when a user initiates a download by specifying a region to download at once.
  - If not otherwise specified, this is also usually referred to as just 'downloading'.
  - This caching is banned by some servers, make sure you comply with the appropriate rules and ToS for your server.

Below are some special highlights in no particular order - my personal pick of things I "quite like" and spent a lot of time on. By no means is this an exhaustive list!

<details>
<summary> Advanced Region Selection </summary>

Select a multitude of region shapes for displaying to the user and downloading. Choose from a standard rectangle/square, a circle, or a line-based region.

- Rectangle regions are formed from 2 coordinates, representing the north-west and south-east corners. The code automatically creates the other necessary corners.  
- Circle regions are formed from a center coordinate and a radius. Internal 'outline' coordinates are generated per degree automatically from this information.  
- Line-based regions are formed from multiple coordinates and a radius, creating a locus. Internal 'outline' coordinates are generated for every vertex and curve.

</details>

<details>
<summary> Device Status Controlled Bulk Downloading </summary>

Run tests automatically before starting a bulk download, to consider multiple device-independent factors such as battery level/status and network connectivity.

Write your own tests or use the default checks. For more information see the API Documentation on `PreDownloadChecksCallback`.
</details>

<details>
<summary> Recoverable Downloads </summary>

Oh no! For some reason, the download stopped unexpectedly, and now you have no way of knowing which region was created to download again. But, with recoverable downloads by default, you do have a way.

When starting a download, a special one-off file is stored that contains persistent information about the running download. This file is then deleted at the end of a successful download.

Therefore, if the file exists, but there is no ongoing download, an error must have happened. You can use the inbuilt functionality to check for recoverable downloads on initialization, and restart them quickly and easily if necessary.

Note that this does not track the number of completed tiles, and the download must be restarted from the beginning. Using `preventRedownload`, however, is a workaround, and will quickly skip through present tiles, getting quickly to ones which still need to be downloaded.
</details>

<details>
<summary> Sea Tile Removal </summary>

When bulk downloading large regions, storage space can be saved by removing blank, blue, sea tiles. They contain no useful information, so can just be ignored, thus freeing up space for more useful tiles.

Checks for sea tiles are done using byte-to-byte comparison between a sample taken from the tile at lat/long 0/0 and the tile that has just been downloaded. If they match, the tile must be sea. This also means that tiles containing ferry pathways, for example, are downloaded, as they are not entirely sea.

Note that this does not reduce data or time consumption: tiles still have to be downloaded to be compared.
</details>

<details>
<summary> Multithreaded Downloading </summary>

Instead of repeating the process of downloading an image and writing it to system one at a time, you can make use of the inbuilt multi-threading functionality to repeat the above process along side each other simultaneously.

For example, 10 simultaneous threads would work through 100 tiles approximately 10x quicker than 1 thread: each thread would get approximately 10 tiles. In reality, the speed gain is unlikely to be as significant as in theory, but it will be similar. However, speed does start to decrease at a certain number of threads: there is an optimal point at about 10-20 threads.

Note that using multithreading will increase power consumption significantly and may be less stable if there are too many threads.  
Some tile servers ban multithreaded downloading, even paid ones, as it puts a lot of strain on servers.

This functionality is enabled by default with a thread count of 10.
</details>

<details>
<summary> Background Downloading </summary>

Instead of downloading in the 'foreground', there is an option (only on Android) to start a download in the 'background'.

There is some confusion about the way background process handling works on Android, so let me clear it up for you: it is confusing.  
Each vendor (eg. Samsung, Huawei, Motorola) has there own methods of handling background processes. Some manage it by providing the bare minimum user-end management, resulting in process that drain battery because they can't be stopped easily; others manage it by altogether banning/strictly limiting background processes, resulting in weird problems and buggy apps; many manage it by some layer of control on top of Android's original controls, making things more confusing for everyone.  
Therefore there is no guaranteed behaviour when using this functionality. You can see how many vendors will treat background processes here: [dontkillmyapp.com](https://dontkillmyapp.com/); you may wish to link your users to this site so they can properly configure your app to run in the background.

To try and help your users get to the right settings quicker, use the `StorageCachingTileProvider.requestIgnoreBatteryOptimizations()` method before starting a background download. This will interrupt the app with either a dialog or a settings page where they can opt-in to reduced throttling. There is no guarantee that this will work, but it should help: this is not required and the background download will still *try* to run even if the user denies the permissions.

If the download doesn't start, your app may be being throttled by the system already. Try setting `useAltMethod` to `true` in this case, or fallback to downloading in the foreground.

Background downloading does have some advantages, however:

- Takes strain off of main threads and into special background threads - may run faster on some devices
- Push notifications to keep the user updated
- Should? still run when app is minimized or screen is locked

Foreground downloading might also work when app is minimized or the screen is locked, but it's better practise to use a dedicated, registered background process.

The background download functionality has been disabled on iOS, because of the even stricter restrictions - note that iOS installation still requires extra setup (see Installation).
</details>

## [API Details](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html)

Because of the many parts to this package and the small number of maintainers (only me), there is no 'full documentation' for everything in this README or in any wiki.

Documentation has been written into the source code: you can see every public API element (and some 'private' ones) in the [auto generated docs (dartdoc)](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html). This contains all of the information for each element and suggested uses for your application.  
Content visible there is also visible whilst writing code (in most editors/IDEs), so you should rarely need to leave the comfort of your editor. This results in creativity, as it's easy to progressively browse through the API to find new functionality.

Some documentation can be seen for some 'private'/internal elements, marked with `@internal`. Whilst it is possible to use these in your code, you should never need to. Using one will cause a warning to appear in your IDE.

Having said all of that, below is a brief overview of the top-level elements to get you started:

### `StorageCachingTileProvider()`

The tile provider and the 'frontend' of the operation.

Integrates with `flutter_map` by registering as a tile provider that also caches tiles as users browse over them. Also contains all of the functionality needed to start, manage, and stop bulk downloads.

### `MapCachingManager()`

The 'backend' of the operation.

Handles the filesystem interactions, allowing you to easily find all the possible information you could ever want about a cache or store.

## Migrate to v4 from v3

Unfortunately, because so much has changed, the best way to migrate is to rewrite the appropriate areas of your project with the new features.
I've tried to make v4 even easier to understand and use, even with all the new functionality, so I hope you don't find this too time consuming.

## Limitations, Known Bugs & Testing

- This package does not support the web platform. A fix for this is unlikely to appear because the web platform is ill-suited for caching anyway.
- This package has not been tested on the iOS platform, and as a result, bugs may appear more frequently than on Android. I am currently looking into options to test on iOS.
- It is unspecified and untested how tile selection code will behave when regions stretch due to latitude and longitude changes in projection. Similarly, code may behave strangely around extremities such as (-)180°. To prevent errors, the values of the calculation have been clamped to a valid minimum and maximum, but this causes other side effects. To prevent unwanted results, try to use small regions, no larger than the size of Europe, and keep them away from the extremities.

Due to the large amounts of functionality, each with many different variations, it is nearly impossible to find many bugs. Therefore, if you find a bug, please do file an issue on GitHub, and I will do my very best to get it fixed quickly.

## Supporting Me

A donation through my Ko-Fi page would be much appreciated - Ko-fi doesn't take a fee, so all donated money goes to me:  
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N151INN)  
but, if you can't or won't, a star on GitHub and a like on pub.dev would also go a long way!

Every donation/star/like gives me 'mental fuel' to continue my open-source projects and lets me know that I'm doing a good job.

## Credits

The basis of this library was originally coded by [bugDim88](https://github.com/bugDim88), and improved upon by [multiple people](https://github.com/JaffaKetchup/flutter_map_tile_caching/graphs/contributors).
