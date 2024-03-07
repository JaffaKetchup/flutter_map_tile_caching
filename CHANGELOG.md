# Sponsors

Many thanks to my sponsors, no matter how much or how little they donated. Sponsorships & donations allow me to continue my projects and upgrade my hardware/setup, as well as allowing me to have some starting amount for further education and such-like.

* @tonyshkurenko
* @Mmisiek
* @huulbaek
* @andrewames
* @ozzy1873
* @eidolonFIRE
* @weishuhn
* @mohammedX6
* and 3 anonymous or private donors

# Changelog

## [9.0.0] - "Hundreds of hours" - 2024/XX/XX

This update has essentially rewritten FMTC from the ground up, over hundreds of hours. It focuses on:

* improved future maintainability by modularity
* improved stability & performance across the board
* support of 'tiles across stores': reduced duplication

I would hugely appricate any donations - please see the documentation site, GitHub repo, or pub.dev package.

I would also like to thank all those who have been waiting and contributing their feedback throughout the process: it means a lot to me that FMTC is such a crucial component to your application.

And without further ado, let's get the biggest changes out of the way first:

* Added support for modular storage/root backends through `FMTCBackend`
  * Removed Isar support  
    Isar unfortunately caused too many stability issues, and is not as actively maintained as I would like (I can sympathise :D).
  * Added ObjectBox as the default backend (`FMTCObjectBoxBackend`)  
    ObjectBox uses the same underlying database technology as Isar (MBDX), but is more maintained, and I'm hoping, more stable. Note that ObjectBox declares it only supports 64-bit systems, whereas Isar was just 'mostly unstable' on 32-bit systems until recently (where is also became 64-bit only): it's time for the future!
  * It is expected that backends support a many-to-many relationship between tiles and stores  
    This has reduced duplication between stores and tiles massively, and now allows for smaller, fine-grained region control. The default backend supports this with as minimal hit to performance as possible, although of course, database operations are now considerably more complex than in previous versions, and so therefore will take slightly longer. In practise, there is no noticeable performance difference.
  * It is expected that backends cache statistics instead of calculating them at get time  
    This has decreased the time spent fetching basic statistics, and allowed for increased efficiency when getting multiple stats at once. Of course, there is some impact on performance at write time: it must all be accurately tracked, else it will be inaccacurate/out-of-sync.

* Restructured top-level access APIs
  * Deprecated `StoreDirectory` & `RootDirectory` in favour of `FMTCStore` and `FMTCRoot`  
    The term 'directory' has been misleading for a couple of years now, as it hasn't been actual filesystem directories storing information since the introduction of v7.
  * Removed the `FlutterMapTileCaching`/`FMTC` access object, in favour of `FMTCStore` and `FMTCRoot` direct constructors  
    Much of the configuration and state management performed by this top-level object and it's close relatives were transferred to the backend, and as such, there is no longer a requirement for these objects.
  * Removed support for synchronous operations (and renamed asynchronous operations to reflect this)  
    These were incompatible with the new `Isolate`d `FMTCObjectBoxBackend`, and to keep scope reasonable, I decided to remove them, in favour of backends implementing their own `Isolate`ion as well.

* Reimplemented bulk downloading
  * Added `CustomPolygonRegion`, a `BaseRegion` that is formed of any* outline
  * Added pause and resume functionality
  * Added rate limiting functionality
  * Added support for multiple simultaneous downloads
  * Improved developer experience by refactoring `DownloadableRegion` and `startForeground`
  * Improved download speed significantly
  * Fixed instability and bugs when cancelling buffering downloads
  * Fixed generation of `LineRegion` tiles by reducing number of redundant duplicate tiles
  * Fixed usage of `obscuredQueryParams`
  * Removed support for bulk download buffering by size capacity
  * Removed support for custom `HttpClient`s
* Deprecated plugins
  * Transfered support for import/export operations to core (`RootExternal`)
  * Deprecated support for background bulk downloading
* Migrated to Flutter 3.19 and Dart 3.3
* Migrated to flutter_map v6

With those out of the way, we can take a look at the smaller changes:

* Improved error handling (especially in backends)
* Added `StoreManagement.pruneTilesOlderThan` method
* Added shortcut for getting multiple stats: `StoreStats.all`
* Added secondary check to `FMTCImageProvider` to ensure responses are valid images
* Replaced public facing `RegionType`/`type` with Dart 3 exhaustive switch statements through `BaseRegion/DownloadableRegion.when` & `RecoverableRegion.toRegion`
* Removed HTTP/2 support

In addition, there's been more action in the surrounding enviroment:

* Created a miniature testing tile server
* Created automated tests for tile generation
* Improved & simplified example application
  * Removed update mechanism
  * Added tile-by-tile/live download following

## [8.0.1] - 2023/07/29

* Fixed bugs when generating tiles for `LineRegion`

## [8.0.0] - 2023/05/05

* Bulk downloading has been rewritten to use a new implementation that generates tile coordinates at the same time as downloading tiles
  * `check`ing the number of tiles in a region now uses a significantly faster and more efficient implementation
  * Starting a download no longer causes significant memory bloat, which could crash the app on large regions
  * Starting a download is now much quicker and closer to constant time, as tile coordinates don't need to be pre-generated
  * Cancelling a download no longer causes many `QueueCancelledException`s to be thrown, which could crash the app
  * Removed reliance on 'queue' dependency in order to squeeze as much speed as possible out of the new implementation
* Other improvements
  * `initialise` now automatically renames databases if their filename ID doesn't match their name hash
  * `initialise` can now throw a more useful `FMTCInitialisationException` with improved clarity
  * Methods that require a valid store descriptor object to be present now throw `FMTCDamagedStoreException` if it is not present
* Other bug fixes
  * `FMTCImageProvider`'s oldest tile deleter & bulk downloading now respects custom root directories
  * `FMTCImageProvider` now evicts failed images from Flutter's `ImageCache` to prevent errors
* Added support for custom `HttpClient`s/`BaseClient`s
* Added support for Isar v3.1 (bug fixes & stability improvements)

> **Version 7 was made unstable due to a non-semantic versioning compliant update of a dependency.**  
> **This means the pub version resolver can never resolve FMTC v7 without introducing compilation errors.**
>
> ## [7.2.0] - 2023/03/03
>
> * Stability improvements
>   * Starting multiple downloads no longer causes `LateInitializationErrors`
>   * Migrator storage and memory usage no longer spikes as significantly as previously, thanks to transaction batching
>   * Opening and processing of stores on initialisation is more robust and less error-prone to filename variations
>   * Root statistic watching now works on all platforms
> * Multiple minor bug fixes and documentation improvements
> * Added `maxStoreLength` config to example app
>
> ## [7.1.2] - 2023/02/18
>
> * Minor bug fixes
>
> ## [7.1.1] - 2023/02/16
>
> * Major bug fixes
> * Added debug mode
>
> ## [7.1.0] - 2023/02/14
>
> * Added URL query params obscurer feature
> * Added `headers` and `httpClient` parameters to `getTileProvider`
> * Minor documentation improvements
> * Minor bug fixes
>
> ## [7.0.2] - 2023/02/12
>
> * Minor changes to example application
>
> ## [7.0.1] - 2023/02/11
>
> * Minor bug fixes
> * Minor improvements
>
> ## [7.0.0] - 2023/02/04
>
> * Migrated to Isar database
> * Major performance improvements, thanks to Isar
> * Added buffering to bulk tile downloading
> * Added method to catch tile retrieval errors
> * Removed v4 -> v5 migrator & added v6 -> v7 migrator
> * Removed some synchronous methods from structure management
> * Removed 'fmtc_advanced' import file
>
> Plus the usual:
>
> * Minor performance improvements
> * Bug fixes
> * Dependency updates
> * Documentation improvements

## [6.2.0] - 2022/10/25

* Performance improvements
* Changed license to GPL v3
* Updated dependencies

## [6.1.0] - 2022/09/23

* Fixed bugs within import functionality
* Added support for notifications on Android 13+
* Improved performance
* Updated dependencies

## [6.0.1] - 2022/09/11

* Improved stability
* Updated dependencies

## [6.0.0] - 2022/09/05

* Added support for flutter_map v3
* Fixed bugs
* Improved example application

## [5.1.1] - 2022/08/12

* Fixed bugs
* Updated dependencies
* Improved example application

## [5.1.0] - 2022/08/09

* Added import/export functionality
* Improved example application
* Improved documentation
* Fixed bugs

## [5.0.0] - 2022/08/03

* Renamed and refactored internal and public APIs, ready for release
* Added `successfulSize` statistic to `DownloadProgress`
* Improved example application
* Improved documentation
* Fixed bugs

## [5.0.0-dev.6] - 2022/07/29

* Polish and preparations for full v5 release
* Moved `migrator` into `rootDirectory` to fix bugs
* Converted `DownloadManagement` to a singleton object
* Finished example application
* Improved documentation
* Fixed bugs

## [5.0.0-dev.5] - 2022/07/25

* Improved download time estimates and added tiles per second statistic
* Added custom filesystem string sanitiser setting to `FMTCSettings`
* Improved statistic watchers
* Improved example application
* Improved documentation
* Fixed bugs

## [5.0.0-dev.4] - 2022/07/19

* Added cache hits and misses statistics
* Added v4 to v5 file structure migration methods
* Reworked `invalidateCachedStatistics`
* Improved documentation
* Fixed bugs

## [5.0.0-dev.3] - 2022/07/17

* Improved example application
* Updated Gradle for example application
* Improved documentation
* Improved background downloading implementation
* Added support for 'flutter_map' v2.0.0
* Added Windows support to example application
* Fixed multiple bugs

## [5.0.0-dev.2] - 2022/06/13

* Example application improvements
* README documentation improvements
* Deprecated `preDownloadChecksCallback`
* Added `checkTileCached` to tile provider
* Refactored and reorganised public APIs (eg. moved `tileImage` from `stats` to `manage`)

## [5.0.0-dev.1] - 2022/06/01

* Widespread syntax changes
* Added custom metadata storage functionality
* Added statistic caching to improve performance somewhat
* Start of new example application for better performance and Material 3 support
* Documentation improvements
* Specification of platform support
* Internal refactoring and reorganization

## [4.0.1] - 2022/02/28

* Fix bug #45 (on GitHub)

## [4.0.0] - 2022/02/26

* Miscellaneous changes
* Check file system watching is supported before usage
* Incorporate all pre-releases

## [4.0.0-dev.11] - 2022/02/20

* Example improvements - new example app still in progress
* Improve estimations for downloading durations (still needs tweaking)
* Upgraded Dart and Flutter versions
* Fix bug #41 (on GitHub)

## [3.0.4] - 2022/02/10

* Fix bug #41 (on GitHub)
* Bumped 'flutter_local_notifications' version to v9.2.0

## [4.0.0-dev.10] - 2022/01/26

* Fixed major performance issues
* Example improvements - new example app still in progress
* Tweaked `AsyncMapCachingManager` & `MapCachingManager`
* Replaced assertions with throws
* Internal refactoring
* Added build tools
* Recovery system reworked - needs testing
* Added linter

## [4.0.0-dev.9] - 2021/12/27

* Added new functionality: `AsyncMapCachingManager` (extension methods)
* Added new functionality: debouncing for `watch...` methods in `MapCachingManager`
* Added new functionality: `emptyStore()` in `MapCachingManager`
* Fixed inaccurate size reporting
* Example improvements - new example app still in progress
* General changes to README

## [4.0.0-dev.8] - 2021/12/09

* New example app (in progress)
* Added `coverImage()` functionality
* General improvements
* Fixed issues for web compilation (needs more testing)
* Acknowledged issue with dynamic tile source swapping (see #31 on GitHub), still needs resolving

## [4.0.0-dev.7] - 2021/11/06

* Major performance improvements through custom `ImageProvider`
* Automatic cache store creation on initialization of `StorageCachingTileProvider` and `MapCachingManager`
* Added watchable stream to `MapCachingManager` to listen to changes in statistics
* Removed 'network_to_file_image' dependency
* Fixed and improved 'browse caching' logic
* Better hidden internal constructors
* Deprecated and removed some functionality

## [4.0.0-dev.6] - 2021/10/10

* Added pre-download check functionality
* Added ability to change caching behaviour
* Rewritten tile provider part to be smaller and more efficient
* Updated & fixed example
* Project reorganisation
* Updated tests

## [4.0.0-dev.5+1] - 2021/10/08

* Deprecated circle extensions to match new 'standard'
* Pleased Flutter formatter
* Updated example
* Fixed serious `Isolate` bugs that prevented downloads by removing the isolate system
* Added 'prettyPaint'ing to `LineRegion`
* Some performance improvements and internal refactoring
* Added more Installation instructions
* *BUG* `LineRegion` does not report an estimated amount of tiles in the example
* Updated tests

## [4.0.0-dev.5] - 2021/09/27

* Added multithreading to download loop (thanks to GitHub contributor [Abdelrahman-Sherif](https://github.com/Abdelrahman-Sherif))
* Add line tile loop (not complete, some bugs)
* Added precise recovery mode (requires testing)
* Changed tests to only use one thread
* Edited README
* Taken some features out of experimental
* Removed broken `compressionQuality`
* Removed encoded polyline conversion functionality
* ... and more

## [3.0.3] - 2021/09/12

* Fix bug #32 (on GitHub)
* Update .gitignore
* Update README to recommend v4

## [4.0.0-dev.4] - 2021/09/02

* Created recovery system
* Added new examples
* Improved automated tests
* Deprecated shape chooser
* Deprecated some extension methods
* Working on example app
* Add more customization to background download notifications
* Some testing and bug fixes still required
* Update to documentation README still required

## [4.0.0-dev.3] - 2021/08/29

* Created automated tests
* Reworked `DownloadProgress()`, adding many more statistics
* Add way to rename existing store
* Large refactoring and reduction of code duplication
* Performance improvements
* Marked some experimental functionality as experimental, ready for release
* Added re-download prevention option
* Added sea tile removal
* Added compression option (needs manual testing)

## [3.0.2] - 2021/07/25

* Fix bug #20 (on GitHub)
* Updated README

## [4.0.0-dev.2] - 2021/07/20

* Bug fixes
* Re-introduction of tile count limiter
* Improve documentation

## [4.0.0-dev.1] - 2021/07/20

* Migrate to filesystem API
* Add basic preload surroundings widgets
* Fix bugs
* Improve documentation
* Allow manual control over `forceAlarmManager`, off by default
* Remove very old APIs
* Deprecate old APIs
* Removal of tile count limiter

## [3.0.1] - 2021/07/20

* Fix bug #17 (on GitHub)
* Removed an invalid example
* Updated README

## [3.0.0] - 2021/07/04

* Last quick fixes
* Publish to pub.dev
* Use AlarmManager for background tasks to resolve issues
* Deprecate old APIs

## [3.0.0-dev.2] - 2021/07/01

* Move to more appropriate date system for changelog
* Rewritten documentation
* Improved examples
* Improved easy shape chooser

## [3.0.0-dev.1] - 30/06/2021

* Huge refactoring to make methods easier to use and more flexible
* Addition of circle region
* Refactoring of square region
* Removal of tuple from main methods
* Addition of ability to exclude pure sea tiles
* Addition of multiple caching tables
* Performance improvements
* Add donation method
* Add GitHub actions
* Added easy shape chooser

## [2.0.2] - 04/06/2021

* Publish to pub.dev
* Null safety finalised

## [2.0.1] - 04/06/2021

* Attempt to publish (failed)

## [2.0.0] - 23/05/2021

* Increased default values (increased default cache limit (tiles) to 20000 and default cache duration to 31 days)
* Improved readme (added badges, simplified a calculation and increased detail on how to install and import)
* Re-organised file structure to match recommended layout
* Added changelog heading to please linter
* Fixed issues with WMS tile layer options

## [1.1.0] - 23/05/2021

* **DO NOT UPDATE TO THIS VERSION as there is a full new release coming soon**
* Enable sound null-safety (**Breaking Change:** Only SDK `>= 2.12.0` allowed)

## [1.0.1] - 09/04/2021

* Initial release
* First publish to pub.dev
