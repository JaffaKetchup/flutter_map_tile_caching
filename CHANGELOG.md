# Changelog

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

## [2.0.0] - 23/05/2021 - Breaking

* Increased default values (increased default cache limit (tiles) to 20000 and default cache duration to 31 days)
* Improved readme (added badges, simplified a calculation and increased detail on how to install and import)
* Re-organised file structure to match recommended layout
* Added changelog heading to please linter
* Fixed issues with WMS tile layer options

## [1.1.0] - 23/05/2021 - Breaking

* **DO NOT UPDATE TO THIS VERSION as there is a full new release coming soon**
* Enable sound null-safety (**Breaking Change:** Only SDK `>= 2.12.0` allowed)

## [1.0.1] - 09/04/2021

* Initial release
* First publish to pub.dev
