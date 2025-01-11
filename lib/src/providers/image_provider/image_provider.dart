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
          options: options,
          provider: provider,
          key: key,
          finishedLoadingBytes: finishedLoadingBytes,
          startedLoading: startedLoading,
          requireValidImage: true,
        ).then(ImmutableBuffer.fromUint8List).then((v) => decode(v)),
        scale: 1,
        debugLabel: coords.toString(),
        informationCollector: () {
          final tileUrl = provider.getTileUrl(coords, options);

          return [
            DiagnosticsProperty('Stores', provider.stores),
            DiagnosticsProperty('Tile coordinates', coords),
            DiagnosticsProperty('Tile URL', tileUrl),
            DiagnosticsProperty(
              'Tile storage-suitable UID',
              provider.urlTransformer?.call(tileUrl) ?? tileUrl,
            ),
          ];
        },
      );

  /// {@macro fmtc.tileProvider.provideTile}
  static Future<Uint8List> provideTile({
    required TileCoordinates coords,
    required TileLayer options,
    required FMTCTileProvider provider,
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

      if (currentTLIR != null) {
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
        coords: coords,
        options: options,
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
          other.coords == coords &&
          other.provider == provider);

  @override
  int get hashCode => Object.hash(coords, provider);
}
