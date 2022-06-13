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
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // Suitable for most situations
import 'package:flutter_map_tile_caching/fmtc_advanced.dart'; // Only import if required functionality is not exposed by 'flutter_map_tile_caching.dart'
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

### Windows, MacOS, Linux

This package declares support for these platforms, but no testing has been conducted, and you will need to make appropriate configurations yourself. Avoid using methods that interact with permissions or background processes

## Example

As of v4, this package contains a full example application showcasing most of the features of this package. Simply clone the this project, enter the 'example' directory, and then build for your desired platform:

- Android & Windows users should run 'androidBuilder.bat'
- Android & Linux/MacOS users should run 'androidBuilder.sh' (bash, untested)

... to build the smallest output .apk files possible.  
There is no build automation for iOS devices: users will need to build manually as usual.

By using the example application, you must comply to your tile server's ToS. OpenStreetMap's (the default throughout the application) can be [found here](https://operations.osmfoundation.org/policies/tiles). If you cannot comply to these rules, you should find one that you can comply to and get the appropriate source URL (which can be customised in the application).  
Some safeguards have been built in to protect servers - specifically in the bulk download screen. You can read more about these by tapping the help icon in the app bar on that page.

Feel free to use the example app as a starting point for your application. Many screens should fit into any app - perhaps with some restyling to fit your app.

## Terminology

If you don't understand the concept of map tiles and servers yet, you should first become familiar with these. Try reading through the flutter_map documentation.

For development with this package, it is essential to become familiar with some terminology used throughout the documentation and API:

- A 'root' (previously 'cache') can hold multiple 'stores'.
  - There is usually only one root per application, but more complex applications may wish to use more than one. In this case, the initialisation function below can be run more than once.
- A 'region' is an area of a map formed by particular rules ('shapes') and coordinates.
- 'Browse caching' or just 'caching' is the caching performed when a user pans over a tile in the map view and it becomes visible.
- 'Bulk downloading' is the caching performed when a user initiates a download by specifying a region to download at once.
  - This caching is banned by some servers, make sure you comply with the appropriate rules and ToS for your server.

## Functionality Highlights

Below are some special highlights in no particular order - my personal pick of things I "quite like" and spent a lot of time on. By no means is this an exhaustive list!

<details>
<summary> Advanced Region Selection </summary>

Select a multitude of region shapes for displaying to the user and downloading. Choose from a standard rectangle/square, a circle, or a line-based region.

- Rectangle regions are formed from 2 coordinates, representing the north-west and south-east corners. The code automatically creates the other necessary corners.  
- Circle regions are formed from a center coordinate and a radius. Internal 'outline' coordinates are generated per degree automatically from this information.  
- Line-based regions are formed from multiple coordinates and a radius, creating a locus. Internal 'outline' coordinates are generated for every vertex and curve.

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

## Usage

*All of this documentation can be found during development in your favourite IDE (such as VSC) due to the abundance of in code docs. To see the full API docs, [visit them here](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html).*

The main basis of this package is the `FlutterMapTileCaching` object, which can be shortened to `FMTC` in code (typedefs used internally) and in documentation.  
There are other high level objects, but they are usually for more advanced usage, and can be explored in more detail through the API documentation.

This singleton must first be initialised, usually in the `main` (asynchronous) function at the start of your app, like this: `FMTC.initialise()`. The function takes a `rootDir` argument, usually `await RootDirectory.normalCache`, and custom global `settings`, which is optional.

Once initialised, it is safe to use `FMTC.instance` (this throws `StateError` if not initialised). At this point, most functionality is accessed through chaining. Any of the following can be chained:

- To use a store without automatically creating it (recommended for performance), use `()` (`call()`). Place the store name inside the parenthesis.
- To use a store and automatically synchronously create it if it doesn't exist, use `[]`. Place the store name inside the parenthesis.
- To use the root directory, use `rootDirectory`.

After this, you can chain any of the following:

| API Getter | Structure | Explanation                                                                                  |
|------------|-----------|----------------------------------------------------------------------------------------------|
|`access`    | Both      | Access the real directory structure - only for advanced usage                                |
|`manage`    | Both      | Perform management tasks, such as creation and deletion                                      |
|`stats`     | Both      | Retrieve statistics, such as size and length                                                 |
|`recovery`  | Roots     | Manage bulk download recovery                                                                |
|`download`  | Stores    | Manage bulk downloads                                                                        |
|`metadata`  | Stores    | Use a simple key-value pair store - suitable for storing simple store related information    |

So, for example, to access statistics for a store, you might use:

```dart
// Recommended if you are certain the store exists, or you don't need to perform actions with the store at this point
final stats = FMTC.instance('storeName').stats;

// Use only if you are not sure the store exists and you can't manually create it asynchronously
final stats = FMTC.instance['storeName'].stats; 
```

The following subsections explain usage of some of the above getters, and more, in more detail.  
Note that many of the methods and getters, for example those under `manage` have asynchronous versions, which are recommended for performance. To use them, if available, just add 'Async' to the end of the method/getter. For example, `ready` and `readyAsync`.

### Tile Provider: `getTileProvider()`

In addition to the above getter, stores (not roots) also have the method `getTileProvider`. This is the point of integration with flutter_map, providing browse caching through a custom image provider, and can be used as so:

```dart
TileLayerOptions(
    tileProvider: FMTC.instance('storeName').getTileProvider(),
),
```

The method optionally takes a `FMTCTileProviderSettings` to override any defaults, whether the package default, or the default set in the initialisation function.

`FMTCTileProviderSettings` can take the following arguments:

| Argument              | Type              | Explanation                                                                           | Default                       |
|-----------------------|-------------------|---------------------------------------------------------------------------------------|-------------------------------|
|`behavior`             | `CacheBehavior`   | Logic used for storage and retrieval of tiles                                         | `CacheBehavior.cacheFirst`    |
|`cachedValidDuration`  | `Duration`        | Duration until a tile expires and needs to be fetched again                           | `const Duration(days: 16)`    |
|`maxStoreLength`       | `int`             | Maximum number of tiles allowed in a cache store before the oldest tile gets deleted  | `0`: disabled                 |

### Manage: `manage`

| API        | Structure | Explanation                                                                                  |
|------------|-----------|----------------------------------------------------------------------------------------------|
|`ready`     | Both      | Check if the necessary directory structure exists                                            |
|`create()`  | Both      | Create the necessary directory structure, or do nothing if it already exists                 |
|`delete()`  | Both      | Delete the directory structure, fail if it doesn't exist                                     |
|`reset()`   | Roots     | Reset the directory structure (delete and recreate)                                          |
|`reset()`   | Stores    | Reset the tiles directory structure (delete and recreate)                                    |
|`rename()`  | Stores    | Safely rename the store and the necessary directories                                        |
|`tileImage` | Stores    | Retrieve a tile and extract it's [Image] asynchronously                                      |

### Statistics: `stats`

Many statistics are cached for better performance, as some take a long time to calculate. If this causes problems, chain `noCache` before the below API getters/methods, like this: `stats.noCache.storeSize`. Alternatively, clear the currently cached statistics using `invalidateCachedStatistics()`. This is automatically called when new tiles are added to the store.

| API               | Structure | Explanation                                                                   |
|-------------------|-----------|-------------------------------------------------------------------------------|
|`watchChanges()`   | Both      | Use a file system watcher to watch for changes, useful for a `StreamBuilder`  |
|`storesAvailable`  | Roots     | List all the currently ready stores under the root                            |
|`rootSize`         | Roots     | Get the current root size in KiB including all sub-stores                     |
|`rootLength`       | Roots     | Get the number of tiles currently cached in all sub-stores                    |
|`storeSize`        | Stores    | Get the current store size in KiB                                             |
|`storeLength`      | Stores    | Get the number of tiles currently cached                                      |

## Migrate to v5 from v4

--- Rewriting as of v5 ---

## Limitations, Known Bugs & Testing

- This package does not support the web platform. A fix for this is unlikely to appear because the web platform is ill-suited for caching anyway.
- This package has not been tested on the iOS, Windows, MacOS, or Linux platforms, and as a result, bugs may appear more frequently than on Android. I am currently looking into options to test on these other platforms.
- It is unspecified and untested how tile selection code will behave when regions stretch due to latitude and longitude changes in projection. Similarly, code may behave strangely around extremities such as (-)180°. To prevent errors, the values of the calculation have been clamped to a valid minimum and maximum, but this causes other side effects. To prevent unwanted results, try to use small regions, no larger than the size of Europe, and keep them away from the extremities.

Due to the large amounts of functionality, each with many different variations, it is nearly impossible to find many bugs. Therefore, if you find a bug, please do file an issue on GitHub, and I will do my very best to get it fixed quickly.

## Supporting Me

A donation through my Ko-Fi page would be much appreciated - Ko-fi doesn't take a fee, so all donated money goes to me:  
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N151INN)  
but, if you can't or won't, a star on GitHub and a like on pub.dev would also go a long way!

Every donation/star/like gives me 'mental fuel' to continue my open-source projects and lets me know that I'm doing a good job.

## Credits

The basis of this library was originally coded by [bugDim88](https://github.com/bugDim88), and improved upon by [multiple people](https://github.com/JaffaKetchup/flutter_map_tile_caching/graphs/contributors).
