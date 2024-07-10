// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

class DebugNotifierInfo {
  DebugNotifierInfo._();

  /// Indicates whether the tile completed loading successfully
  ///
  /// * `true`:  completed
  /// * `false`: errored
  late final bool didComplete;
}

/// A specialised [ImageProvider] that uses FMTC internals to enable browse
/// caching
///
/// TODO: Improve hits and misses
/// TODO: Debug tile output
class _FMTCImageProvider extends ImageProvider<_FMTCImageProvider> {
  /// Create a specialised [ImageProvider] that uses FMTC internals to enable
  /// browse caching
  _FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
    required this.startedLoading,
    required this.finishedLoadingBytes,
  });

  /// An instance of the [FMTCTileProvider] in use
  final FMTCTileProvider provider;

  /// An instance of the [TileLayer] in use
  final TileLayer options;

  /// The coordinates of the tile to be fetched
  final TileCoordinates coords;

  /// Function invoked when the image starts loading (not from cache)
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the `httpClient` only
  /// after all tiles have loaded.
  final void Function() startedLoading;

  /// Function invoked when the image completes loading bytes from the network
  ///
  /// Used with [startedLoading] to safely dispose of the `httpClient` only
  /// after all tiles have loaded.
  final void Function() finishedLoadingBytes;

  @override
  ImageStreamCompleter loadImage(
    _FMTCImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // Closed by `getBytes`
    // ignore: close_sinks
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: getBytes(
        coords: coords,
        options: options,
        provider: provider,
        key: key,
        chunkEvents: chunkEvents,
        finishedLoadingBytes: finishedLoadingBytes,
        startedLoading: startedLoading,
        requireValidImage: true,
      ).then(ImmutableBuffer.fromUint8List).then((v) => decode(v)),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: coords.toString(),
      informationCollector: () => [
        DiagnosticsProperty('Store names', provider.storeNames),
        DiagnosticsProperty('Tile coordinates', coords),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  /// {@template fmtc.imageProvider.getBytes}
  /// Use FMTC's caching logic to get the bytes of the specific tile (at
  /// [coords]) with the specified [TileLayer] options and [FMTCTileProvider]
  /// provider
  ///
  /// Used internally by [_FMTCImageProvider.loadImage]. [loadImage] provides
  /// a decoding wrapper, but is only suitable for codecs Flutter can render.
  ///
  /// Therefore, this method does not make any assumptions about the format
  /// of the bytes, and it is up to the user to decode/render appropriately.
  /// For example, this could be incorporated into another [ImageProvider] (via
  /// a [TileProvider]) to integrate FMTC caching for vector tiles.
  ///
  /// ---
  ///
  /// [key] is used to control the [ImageCache], and should be set when in a
  /// context where [ImageProvider.obtainKey] is available.
  ///
  /// [chunkEvents] is used to improve the quality of an [ImageProvider], and
  /// should be set when [MultiFrameImageStreamCompleter] is in use inside an
  /// [ImageProvider.loadImage]. Note that it will be closed by this method.
  ///
  /// [startedLoading] & [finishedLoadingBytes] are used to indicate to
  /// flutter_map when it is safe to dispose a [TileProvider], and should be set
  /// when used inside a [TileProvider]'s context (such as directly or within
  /// a dedicated [ImageProvider]).
  ///
  /// [requireValidImage] is `false` by default, but should be `true` when
  /// only Flutter decodable data is being used (ie. most raster tiles) (and is
  /// set `true` when used by [loadImage] internally). This provides an extra
  /// layer of protection by preventing invalid data from being stored inside
  /// the cache, which could cause further issues at a later point. However, this
  /// may be set `false` intentionally, for example to allow for vector tiles
  /// to be stored. If this is `true`, and the image is invalid, an
  /// [FMTCBrowsingError] with sub-category
  /// [FMTCBrowsingErrorType.invalidImageData] will be thrown - if `false`, then
  /// FMTC will not throw an error, but Flutter will if the bytes are attempted
  /// to be decoded (now or at a later time).
  /// {@endtemplate}
  static Future<Uint8List> getBytes({
    required TileCoordinates coords,
    required TileLayer options,
    required FMTCTileProvider provider,
    Object? key,
    StreamController<ImageChunkEvent>? chunkEvents,
    void Function()? startedLoading,
    void Function()? finishedLoadingBytes,
    bool requireValidImage = false,
  }) async {
    final currentTileDebugNotifierInfo = DebugNotifierInfo._();

    void close({required bool didComplete}) {
      finishedLoadingBytes?.call();

      if (key != null) {
        scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      }
      if (chunkEvents != null) {
        unawaited(chunkEvents.close());
      }

      provider._internalTileLoadingDebugger
        ?..value[coords] =
            (currentTileDebugNotifierInfo..didComplete = didComplete)
        ..notifyListeners();
    }

    startedLoading?.call();

    final Uint8List bytes;
    try {
      bytes = await _internalGetBytes(
        coords: coords,
        options: options,
        provider: provider,
        chunkEvents: chunkEvents,
        requireValidImage: requireValidImage,
        currentTileDebugNotifierInfo: currentTileDebugNotifierInfo,
      );
    } catch (err, stackTrace) {
      close(didComplete: false);

      if (err is FMTCBrowsingError) {
        final handlerResult = provider.settings.errorHandler?.call(err);
        if (handlerResult != null) return handlerResult;
      }

      Error.throwWithStackTrace(err, stackTrace);
    }

    close(didComplete: true);
    return bytes;
  }

  @override
  Future<_FMTCImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FMTCImageProvider>(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FMTCImageProvider &&
          other.coords == coords &&
          other.provider == provider &&
          other.options == options);

  @override
  int get hashCode => Object.hash(coords, provider, options);
}
