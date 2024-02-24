// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';

/// An [Exception] indicating that there was an error retrieving tiles to be
/// displayed on the map
///
/// These can usually be safely ignored, as they simply represent a fall
/// through of all valid/possible cases, but you may wish to handle them
/// anyway using [FMTCTileProviderSettings.errorHandler].
///
/// Use [type] to establish the condition that threw this exception, and
/// [message] for a user-friendly English description of this exception. Also
/// see the other properties for more information.
class FMTCBrowsingError implements Exception {
  /// An [Exception] indicating that there was an error retrieving tiles to be
  /// displayed on the map
  ///
  /// These can usually be safely ignored, as they simply represent a fall
  /// through of all valid/possible cases, but you may wish to handle them
  /// anyway using [FMTCTileProviderSettings.errorHandler].
  ///
  /// Use [type] to establish the condition that threw this exception, and
  /// [message] for a user-friendly English description of this exception. Also
  /// see the other properties for more information.
  @internal
  FMTCBrowsingError({
    required this.type,
    required this.networkUrl,
    required this.matcherUrl,
    this.request,
    this.response,
    this.originalError,
  }) : message = '${type.explanation} ${type.resolution}';

  /// Defines the condition that threw this exception
  ///
  /// See [message] for a user friendly description of this value.
  final FMTCBrowsingErrorType type;

  /// A user-friendly English description of the [type] of this exception,
  /// suitable for UI display, also with some hints at a potential resolution
  /// or debugging step.
  ///
  /// Need just the description, or just the resolution step? See
  /// [FMTCBrowsingErrorType.explanation] & [FMTCBrowsingErrorType.resolution].
  final String message;

  /// Generated network URL at which the tile was requested from
  final String networkUrl;

  /// Generated URL that was used to find potential existing cached tiles,
  /// taking into account [FMTCTileProviderSettings.obscuredQueryParams].
  final String matcherUrl;

  /// If available, the attempted HTTP request
  ///
  /// Will be available if [type] is not
  /// [FMTCBrowsingErrorType.missingInCacheOnlyMode].
  final Request? request;

  /// If available, the HTTP response streamed from the server
  ///
  /// Will be available if [type] is
  /// [FMTCBrowsingErrorType.negativeFetchResponse] or
  /// [FMTCBrowsingErrorType.invalidImageData].
  final StreamedResponse? response;

  /// If available, the error object that was caught when attempting the HTTP
  /// request
  ///
  /// Will be available if [type] is
  /// [FMTCBrowsingErrorType.noConnectionDuringFetch] or
  /// [FMTCBrowsingErrorType.unknownFetchException].
  final Object? originalError;

  @override
  String toString() => 'FMTCBrowsingError ($type): $message';
}

/// Defines the type of issue that a [FMTCBrowsingError] is reporting
///
/// See [explanation] and [resolution] for more information about each type.
/// [FMTCBrowsingError.message] is formed from the concatenation of these two
/// properties.
enum FMTCBrowsingErrorType {
  /// Failed to load the tile from the cache because it was missing
  ///
  /// Ensure that tiles are cached before using [CacheBehavior.cacheOnly].
  missingInCacheOnlyMode(
    'Failed to load the tile from the cache because it was missing.',
    'Ensure that tiles are cached before using `CacheBehavior.cacheOnly`.',
  ),

  /// Failed to load the tile from the cache or the network because it was
  /// missing from the cache and a connection to the server could not be
  /// established
  ///
  /// Check your Internet connection.
  noConnectionDuringFetch(
    'Failed to load the tile from the cache or the network because it was missing from the cache and a connection to the server could not be established.',
    'Check your Internet connection.',
  ),

  /// Failed to load the tile from the cache or network because it was missing
  /// from the cache and there was an unexpected error when requesting from the
  /// server
  ///
  /// Try specifying a normal HTTP/1.1 [IOClient] when using
  /// [FMTCStore.getTileProvider]. Check that the [TileLayer.urlTemplate] is
  /// correct, that any necessary authorization data is correctly included, and
  /// that the server serves the viewed region.
  unknownFetchException(
    'Failed to load the tile from the cache or network because it was missing from the cache and there was an unexpected error when requesting from the server.',
    'Try specifying a normal HTTP/1.1 `IOClient` when using `getTileProvider`. Check that the `TileLayer.urlTemplate` is correct, that any necessary authorization data is correctly included, and that the server serves the viewed region.',
  ),

  /// Failed to load the tile from the cache or the network because it was
  /// missing from the cache and the server responded with a HTTP code other than
  /// 200 OK
  ///
  /// Check that the [TileLayer.urlTemplate] is correct, that any necessary
  /// authorization data is correctly included, and that the server serves the
  /// viewed region.
  negativeFetchResponse(
    'Failed to load the tile from the cache or the network because it was missing from the cache and the server responded with a HTTP code other than 200 OK.',
    'Check that the `TileLayer.urlTemplate` is correct, that any necessary authorization data is correctly included, and that the server serves the viewed region.',
  ),

  /// Failed to load the tile from the network because it responded with an HTTP
  /// code of 200 OK but an invalid image data
  ///
  /// Your server may be misconfigured and returning an error message or blank
  /// response under 200 OK. Check that the `TileLayer.urlTemplate` is correct,
  /// that any necessary authorization data is correctly included, and that the
  /// server serves the viewed region.
  invalidImageData(
    'Failed to load the tile from the network because it responded with an HTTP code of 200 OK but an invalid image data.',
    'Your server may be misconfigured and returning an error message or blank response under 200 OK. Check that the `TileLayer.urlTemplate` is correct, that any necessary authorization data is correctly included, and that the server serves the viewed region.',
  );

  /// Defines the type of issue that a [FMTCBrowsingError] is reporting
  ///
  /// See [explanation] and [resolution] for more information about each type.
  /// [FMTCBrowsingError.message] is formed from the concatenation of these two
  /// properties.
  @internal
  const FMTCBrowsingErrorType(this.explanation, this.resolution);

  /// A user-friendly English description of this exception, suitable for UI
  /// display
  final String explanation;

  /// Guidance (in user-friendly English) for how this exception might be
  /// resolved, or at least a first debugging step
  final String resolution;
}
