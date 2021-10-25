import 'dart:io';
import 'dart:math';

import 'package:battery_info/enums/charging_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The parent directory of all cache stores, to be used for `parentDirectory` arguments
typedef CacheDirectory = Directory;

/// Use in `preDownloadChecksCallback` in `StorageCachingTileProvider().downloadRegion()` and `StorageCachingTileProvider().downloadRegionBackground()` to ensure the download is OK to start by considering the device's status.
///
/// Setting the parameter to `null` will skip all tests and allow under any circumstances. However, returning `null` from the function will use the default rules: cancel the download if the user is on cellular data or disconnected from the network (not necessarily Internet), or under 15% charge and not connected to a power source.
///
/// Otherwise, the testing function must take a [ConnectivityResult] representing the status of the Internet connection, a nullable-integer representing the battery/charge level of the device if readable, and a nullable-[ChargingStatus] representing the charging status of the device if readable. The function must be asynchronus (to allow for asking the user through something like a dialog box) and return either `true` representing 'let the download continue', or `false` representing 'cancel the download'.
///
/// Useful examples/presets for `preDownloadChecksCallback`:
///
/// 1. Allow under any circumstances
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
/// To check if the tests have failed:
///
/// - In the foreground downloader `StorageCachingTileProvider().downloadRegion()`:
/// ```dart
/// final Stream<DownloadProgress> downloadStream = provider.downloadRegion(...).asBroadcastStream();
/// if (await downloadStream.isEmpty) "<checks have failed>"
/// else "<checks have passed, listen to stream for progress events>"
/// ```
///
/// - In the background downloader `StorageCachingTileProvider().downloadRegionBackground()`:
/// ```dart
/// // Will only fire if the checks have failed; the download will already be cancelled
/// preDownloadChecksFailedCallback: () {}
/// ```
typedef PreDownloadChecksCallback = Future<bool?> Function(
  ConnectivityResult,
  int?,
  ChargingStatus?,
)?;

/// Conversions to perform on an integer number of bytes to get more human-friendly figures. Useful after getting a cache's or cache store's size from `MapCachingManager`, for example.
///
/// All calculations use binary calculations (1024) instead of decimal calculations (1000), and are therefore more accurate.
extension ByteExts on int {
  /// Convert bytes to kilobytes
  double get bytesToKilobytes => this / 1024;

  /// Convert bytes to megabytes
  double get bytesToMegabytes => this / pow(1024, 2);

  /// Convert bytes to gigabytes
  double get bytesToGigabytes => this / pow(1024, 3);
}

@internal
extension ListExtensionsE<E> on List<E> {
  List<List<E>> chunked(int size) {
    List<List<E>> chunks = [];

    for (var i = 0; i < length; i += size)
      chunks.add(this.sublist(i, (i + size < length) ? i + size : length));

    return chunks;
  }
}

@internal
extension ListExtensionsDouble on List<double> {
  double get minNum => this.reduce(math.min);
  double get maxNum => this.reduce(math.max);
}

/// Deprecated due to other better methods. Migrate to `latlong2\'s` [Distance] methods for a more accurate, customizable and efficient result.
@Deprecated(
    'Due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.')
extension LatLngExts on LatLng {
  /// Deprecated due to other better methods. Migrate to `latlong2\'s` [Distance] methods for a more accurate, customizable and efficient result.
  @Deprecated(
      'Due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.')
  double distanceTo(LatLng b) {
    final double p = 0.017453292519943295;
    final double formula = 0.5 -
        math.cos((b.latitude - this.latitude) * p) / 2 +
        math.cos(this.latitude * p) *
            math.cos(b.latitude * p) *
            (1 - math.cos((b.longitude - this.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(formula)) * 1000;
  }

  /// Deprecated due to other better methods. Migrate to `latlong2\'s` [Distance] methods for a more accurate, customizable and efficient result.
  @Deprecated(
      'Due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.')
  double operator >>(LatLng point) {
    return this.distanceTo(point);
  }
}
