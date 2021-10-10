import 'dart:io';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The parent directory of all cache stores, to be used for `parentDirectory` arguments
///
/// Is an alias of `Directory`.
typedef CacheDirectory = Directory;

/// Thrown by `getImage()` when an image could not be loaded either from a HTTP source or from the filesystem
class StorageCachingError implements Exception {
  /// General message describing the error
  String message;

  /// Caching behavior in use at the time of error
  CacheBehavior cacheBehavior;

  /// An error object, if applicable
  Object? extError;

  /// Failed file path, if applicable
  String? filePath;

  /// Failed URL, if applicable
  String? url;

  @internal
  StorageCachingError(
    this.message,
    this.cacheBehavior, {
    this.extError,
    this.filePath,
    this.url,
  });
}

/// Multiple behaviors dictating how caching should be carried out, if at all
enum CacheBehavior {
  /// Only get tiles from the local cache
  cacheOnly,

  /// Only get tiles from online
  onlineOnly,

  /// Get tiles from the local cache, going online to update the cache if `cachedValidDuration` has passed
  cacheFirst,
}

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

/// Deprecated due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.
@Deprecated(
    'Due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.')
extension LatLngExts on LatLng {
  /// Deprecated due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.
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

  /// Deprecated due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.
  @Deprecated(
      'Due to other better methods. Migrate to `latlong2\'s` `Distance().distance()` method for a more accurate, customizable and efficient result.')
  double operator >>(LatLng point) {
    return this.distanceTo(point);
  }
}
