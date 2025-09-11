// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// A specialised [ImageProvider] that uses FMTC internals to enable browse
/// caching
@immutable
class _FMTCImageProvider extends ImageProvider<_FMTCImageProvider> {
  /// Create a specialised [ImageProvider] that uses FMTC internals to enable
  /// browse caching
  const _FMTCImageProvider({
    required this.networkUrl,
    required this.coords,
    required this.provider,
    required this.startedLoading,
    required this.finishedLoadingBytes,
  });

  /// The network URL of the tile at [coords], determined by
  /// [FMTCTileProvider.getTileUrl]
  final String networkUrl;

  /// The coordinates of the tile to be fetched
  ///
  /// Must be set when using the image provider - acts as a key for
  /// [FMTCTileProvider.tileLoadingInterceptor], and is used for some debug
  /// info. Optional when [provideTile] is used directly, if
  /// `tileLoadingInterceptor` functionality is not used.
  final TileCoordinates coords;

  /// An instance of the [FMTCTileProvider] in use
  final FMTCTileProvider provider;

  /// Function invoked when the image starts loading (not from cache)
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the `httpClient`
  /// only after all tiles have loaded.
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
  ) =>
      MultiFrameImageStreamCompleter(
        codec: provideTile(
          coords: coords,
          networkUrl: networkUrl,
          provider: provider,
          key: key,
          finishedLoadingBytes: finishedLoadingBytes,
          startedLoading: startedLoading,
          requireValidImage: true,
        ).then(ImmutableBuffer.fromUint8List).then((v) => decode(v)),
        scale: 1,
        debugLabel: coords.toString(),
        informationCollector: () => [
          DiagnosticsProperty('Stores', provider.stores),
          DiagnosticsProperty('Tile coordinates', coords),
          DiagnosticsProperty('Tile URL', networkUrl),
          DiagnosticsProperty(
            'Tile storage-suitable UID',
            provider.urlTransformer?.call(networkUrl) ?? networkUrl,
          ),
        ],
      );

  /// {@macro fmtc.tileProvider.provideTile}
  static Future<Uint8List> provideTile({
    required FMTCTileProvider provider,
    required String networkUrl,
    TileCoordinates? coords,
    Object? key,
    void Function()? startedLoading,
    void Function()? finishedLoadingBytes,
    bool requireValidImage = false,
  }) async {
    startedLoading?.call();

    final currentTLIR =
        provider.tileLoadingInterceptor != null ? _TLIRConstructor._() : null;

    void close([({Object error, StackTrace stackTrace})? error]) {
      finishedLoadingBytes?.call();

      if (key != null && error != null) {
        scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      }

      if (currentTLIR != null && coords != null) {
        currentTLIR.error = error;

        provider.tileLoadingInterceptor!
          ..value[coords] = TileLoadingInterceptorResult._(
            resultPath: currentTLIR.resultPath,
            error: currentTLIR.error,
            networkUrl: currentTLIR.networkUrl,
            storageSuitableUID: currentTLIR.storageSuitableUID,
            existingStores: currentTLIR.existingStores,
            tileRetrievedFromOtherStoresAsFallback:
                currentTLIR.tileRetrievableFromOtherStoresAsFallback &&
                    currentTLIR.resultPath ==
                        TileLoadingInterceptorResultPath.cacheAsFallback,
            needsUpdating: currentTLIR.needsUpdating,
            hitOrMiss: currentTLIR.hitOrMiss,
            storesWriteResult: currentTLIR.storesWriteResult,
            cacheFetchDuration: currentTLIR.cacheFetchDuration,
            networkFetchDuration: currentTLIR.networkFetchDuration,
          )
          // `Map` is mutable, so must notify manually
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          ..notifyListeners();
      }
    }

    final Uint8List bytes;
    try {
      bytes = await _internalTileBrowser(
        networkUrl: networkUrl,
        provider: provider,
        requireValidImage: requireValidImage,
        currentTLIR: currentTLIR,
      );
    } catch (err, stackTrace) {
      close((error: err, stackTrace: stackTrace));

      if (err is FMTCBrowsingError) {
        final handlerResult = provider.errorHandler?.call(err);
        if (handlerResult != null) return handlerResult;
      }

      rethrow;
    }

    close();
    return bytes;
  }

  @override
  Future<_FMTCImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FMTCImageProvider &&
          other.networkUrl == networkUrl &&
          other.coords == coords &&
          other.provider == provider);

  @override
  int get hashCode => Object.hash(coords, provider);
}
