// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// The result of a tile download during bulk downloading
///
/// Does not contain information about the download as a whole, that is
/// [DownloadProgress]' scope.
///
/// See specific subclasses for more information about the event. This is a
/// sealed tree, so there are a guaranteed knowable set of results.
@immutable
sealed class TileEvent {
  const TileEvent._({
    required this.url,
    required this.coordinates,
    required this.wasRetryAttempt,
  });

  /// The URL used to request the tile
  final String url;

  /// The (x, y, z) coordinates of this tile
  final (int, int, int) coordinates;

  /// Whether this tile was a retry attempt of a [FailedRequestTileEvent]
  ///
  /// Never set if `retryFailedRequestTiles` is disabled.
  ///
  /// Implies that the tile has been emitted before. Care should be taken to
  /// ensure that this does not cause issues (for example, duplication issues).
  ///
  /// (This is also used internally to maintain [DownloadProgress] statistics.)
  final bool wasRetryAttempt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileEvent &&
          url == other.url &&
          coordinates == other.coordinates &&
          wasRetryAttempt == other.wasRetryAttempt);

  @override
  int get hashCode => Object.hashAllUnordered([url, coordinates]);
}

/// The raw result of a successful tile download during bulk downloading
///
/// Successful means the tile was requested from the [url] and recieved an HTTP
/// response of 200 OK, with an image as the body.
@immutable
class SuccessfulTileEvent extends TileEvent
    with TileEventFetchResponse, TileEventImage {
  const SuccessfulTileEvent._({
    required super.url,
    required super.coordinates,
    required super.wasRetryAttempt,
    required this.tileImage,
    required this.fetchResponse,
    required bool wasBufferFlushed,
  })  : _wasBufferFlushed = wasBufferFlushed,
        super._();

  @override
  final Uint8List tileImage;

  @override
  final Response fetchResponse;

  /// Whether this tile triggered the internal bulk download buffer to be
  /// flushed
  ///
  /// There is one buffer per download thread, with the `maxBufferLength` being
  /// shared evenly to all threads. This indication is only applicable for the
  /// thread from which this event was generated (and is therefore not suitable
  /// for public exposure).
  final bool _wasBufferFlushed;
}

/// The raw result of a skipped tile download during bulk downloading
///
/// Skipped means the request to the [url] was not made. See subclasses for
/// specific skip reasons.
@immutable
sealed class SkippedTileEvent extends TileEvent with TileEventImage {
  const SkippedTileEvent._({
    required super.url,
    required super.coordinates,
    required super.wasRetryAttempt,
    required this.tileImage,
  }) : super._();

  @override
  final Uint8List tileImage;
}

/// The raw result of an existing tile download during bulk downloading
///
/// Existing means the request to the [url] was not made because the tile
/// already existed and `skipExistingTiles` was enabled.
///
/// This implies the tile cannot be retry attempt (as tiles in this category are
/// never retried because they can never fail due to a previous
/// [FailedRequestTileEvent]).
@immutable
class ExistingTileEvent extends SkippedTileEvent {
  const ExistingTileEvent._({
    required super.url,
    required super.coordinates,
    required super.tileImage,
  }) : super._(wasRetryAttempt: false);
}

/// The raw result of a sea tile download during bulk downloading
///
/// Sea means the request to [url] was made, and a response was recieved, but
/// the tile image was determined to be a sea tile and `skipSeaTiles` was
/// enabled.
@immutable
class SeaTileEvent extends SkippedTileEvent with TileEventFetchResponse {
  const SeaTileEvent._({
    required super.url,
    required super.coordinates,
    required super.wasRetryAttempt,
    required super.tileImage,
    required this.fetchResponse,
  }) : super._();

  @override
  final Response fetchResponse;
}

/// The raw result of a failed tile download during bulk downloading
///
/// Failed means a request to [url] was attempted, but a HTTP 200 OK response
/// was not recieved. See subclasses for specific failure reasons.
@immutable
sealed class FailedTileEvent extends TileEvent {
  const FailedTileEvent._({
    required super.url,
    required super.coordinates,
    required super.wasRetryAttempt,
  }) : super._();
}

/// The raw result of a negative response tile download during bulk downloading
///
/// Negative response means the request to the [url] was made successfully, but
/// a HTTP 200 OK response was not received.
@immutable
class NegativeResponseTileEvent extends FailedTileEvent
    with TileEventFetchResponse {
  const NegativeResponseTileEvent._({
    required super.url,
    required super.coordinates,
    required super.wasRetryAttempt,
    required this.fetchResponse,
  }) : super._();

  @override
  final Response fetchResponse;
}

/// The raw result of a failed request tile download during bulk downloading
///
/// Failed request means the request to the [url] was not made successfully
/// (likely due to a network issue).
///
/// This tile will be added to the retry queue if `retryFailedRequestTiles` is
/// enabled, and it was not already a retry attempt ([wasRetryAttempt]).
@immutable
class FailedRequestTileEvent extends FailedTileEvent {
  const FailedRequestTileEvent._({
    required super.url,
    required super.coordinates,
    required super.wasRetryAttempt,
    required this.fetchError,
  }) : super._();

  /// The raw error thrown when attempting to make a HTTP request to [url]
  final Object fetchError;
}

/// Indicates a [TileEvent] recieved a HTTP response from the [TileEvent.url]
///
/// The status code may or may not be 200 OK: this does not imply whether the
/// event was successful or not.
mixin TileEventFetchResponse on TileEvent {
  /// The raw HTTP response from the GET request to [url]
  abstract final Response fetchResponse;
}

/// Indicates a [TileEvent] has an associated tile image
///
/// This may be from a successful HTTP response from [TileEvent.url], or it may
/// be retrieved from the cache: this does not imply whether the event was
/// successful or skipped, but it does imply it was not a failure.
mixin TileEventImage on TileEvent {
  /// The raw bytes associated with the [url]/[coordinates]
  abstract final Uint8List tileImage;
}
