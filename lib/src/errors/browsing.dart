// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';
import '../providers/image_provider.dart';

/// An [Exception] indicating that there was an error retrieving tiles to be
/// displayed on the map
///
/// These can usually be safely ignored, as they simply represent a fall
/// through of all valid/possible cases, but you may wish to handle them
/// anyway using [FMTCTileProviderSettings.errorHandler].
///
/// Always thrown from within [FMTCImageProvider] generated from
/// [FMTCTileProvider]. The [message] further indicates the reason, and will
/// depend on the current caching behaviour. The [type] represents the same
/// message in a way that is easy to parse/handle.
class FMTCBrowsingError implements Exception {
  /// Friendly message
  final String message;

  /// Programmatic error descriptor
  final FMTCBrowsingErrorType type;

  /// An [Exception] indicating that there was an error retrieving tiles to be
  /// displayed on the map
  ///
  /// These can usually be safely ignored, as they simply represent a fall
  /// through of all valid/possible cases, but you may wish to handle them
  /// anyway using [FMTCTileProviderSettings.errorHandler].
  ///
  /// Always thrown from within [FMTCImageProvider] generated from
  /// [FMTCTileProvider]. The [message] further indicates the reason, and will
  /// depend on the current caching behaviour. The [type] represents the same
  /// message in a way that is easy to parse/handle.
  @internal
  FMTCBrowsingError(this.message, this.type);

  @override
  String toString() => 'FMTCBrowsingError: $message';
}

/// Pragmatic error descriptor for a [FMTCBrowsingError.message]
///
/// See documentation on that object for more information.
enum FMTCBrowsingErrorType {
  /// Paired with friendly message:
  /// "Failed to load the tile from the cache because it was missing."
  missingInCacheOnlyMode,

  /// Paired with friendly message:
  /// "Failed to load the tile from the cache or the network because it was
  /// missing from the cache and a connection to the server could not be
  /// established."
  noConnectionDuringFetch,

  /// Paired with friendly message:
  /// "Failed to load the tile from the cache or the network because it was
  /// missing from the cache and the server responded with a HTTP code of <$>."
  negativeFetchResponse,
}
