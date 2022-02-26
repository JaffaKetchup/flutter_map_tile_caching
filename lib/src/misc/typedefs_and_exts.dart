import '../../flutter_map_tile_caching.dart';

/// `CacheDirectory` is deprecated in favour of \'dart:io\'s [Directory], which is now automatically exported by \'flutter_map_tile_caching\'. Will be removed in next release.
@Deprecated(
  '`CacheDirectory` is deprecated in favour of \'dart:io\'s `Directory`, which is now automatically exported by \'flutter_map_tile_caching\'. Will be removed in next release',
)
typedef CacheDirectory = Directory;

/// Use in `preDownloadChecksCallback` in the bulk downloaders to ensure the download is OK to start by considering the device's status.
///
/// Setting the parameter to `null` will skip all tests and allow under any circumstances - this is the default, but not recommended. However, returning `null` from the function will use the default rules: cancel the download if the user is on cellular data or disconnected from the network (not necessarily Internet), or under 15% charge and not connected to a power source.
///
/// Otherwise, the testing function must take a [ConnectivityResult] representing the status of the Internet connection, a nullable-integer representing the battery/charge level of the device if readable, and a nullable-[ChargingStatus] representing the charging status of the device if readable. The function must be asynchronus (to allow for asking the user through something like a dialog box) and return either `true` representing 'let the download continue', or `false` representing 'cancel the download'.
///
/// Useful examples/presets for `preDownloadChecksCallback`:
///
/// 1. Allow under any circumstances (default)
/// ```dart
/// preDownloadChecksCallback: null
/// ```
///
/// 2. Use default rules
/// ```dart
/// preDownloadChecksCallback: (_, __, ___) async => null
/// ```
///
/// 3. Only consider battery
/// ```dart
/// preDownloadChecksCallback: (_, lvl, status) async => lvl! > 15 || status == ChargingStatus.Charging
/// ```
///
/// 4. Only consider connectivity
/// ```dart
/// preDownloadChecksCallback: (c, _, __) async => c == ConnectivityResult.wifi || c == ConnectivityResult.ethernet
/// ```
///
/// To check if the tests have failed (if tests do fail, the download will be cancelled for you):
///
/// - In the foreground bulk downloader [StorageCachingTileProvider.downloadRegion] :
/// ```dart
/// final Stream<DownloadProgress> downloadStream = provider.downloadRegion(...).asBroadcastStream();
/// if (await downloadStream.isEmpty) {
///     // Checks have failed: display something to the user
///     alert();
/// }
/// else {
///     // Checks have succeeded: listen to stream for progress events
///     downloadStream.listen();
/// }
/// ```
///
/// - In the background bulk downloader [StorageCachingTileProvider.downloadRegionBackground] :
/// ```dart
/// // Called if the checks fail, otherwise download continues as normal (`callback()`)
/// preDownloadChecksFailedCallback: () {}
/// ```
typedef PreDownloadChecksCallback = Future<bool?> Function(
  ConnectivityResult,
  int?,
  ChargingStatus?,
)?;
