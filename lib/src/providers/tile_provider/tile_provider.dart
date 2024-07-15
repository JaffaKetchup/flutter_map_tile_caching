// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Specialised [TileProvider] that uses a specialised [ImageProvider] to connect
/// to FMTC internals and enable advanced caching/retrieval logic
///
/// To use a single store, use [FMTCStore.getTileProvider].
///
/// To use multiple stores, use the [FMTCTileProvider.multipleStores]
/// constructor. See documentation on [storeNames] and [otherStoresBehavior]
/// for information on usage.
///
/// To use all stores, use the [FMTCTileProvider.allStores] constructor. See
/// documentation on [otherStoresBehavior] for information on usage.
///
/// An "FMTC" identifying mark is injected into the "User-Agent" header generated
/// by flutter_map, except if specified in the constructor. For technical
/// details, see [_CustomUserAgentCompatMap].
///
/// Can be constructed alternatively with [FMTCStore.getTileProvider] to
/// support a single store.
class FMTCTileProvider extends TileProvider {
  /// See [FMTCTileProvider] for information
  FMTCTileProvider.multipleStores({
    required this.storeNames,
    this.otherStoresBehavior,
    FMTCTileProviderSettings? settings,
    this.tileLoadingDebugger,
    Map<String, String>? headers,
    http.Client? httpClient,
  })  : settings = settings ?? FMTCTileProviderSettings.instance,
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        assert(
          storeNames.isNotEmpty || otherStoresBehavior != null,
          '`storeNames` cannot be empty if `allStoresConfiguration` is `null`',
        ),
        super(
          headers: (headers?.containsKey('User-Agent') ?? false)
              ? headers
              : _CustomUserAgentCompatMap(headers ?? {}),
        );

  /// See [FMTCTileProvider] for information
  FMTCTileProvider.allStores({
    required StoreReadWriteBehavior allStoresConfiguration,
    FMTCTileProviderSettings? settings,
    ValueNotifier<TileLoadingDebugMap>? tileLoadingDebugger,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) : this.multipleStores(
          storeNames: const {},
          otherStoresBehavior: allStoresConfiguration,
          settings: settings,
          tileLoadingDebugger: tileLoadingDebugger,
          headers: headers,
          httpClient: httpClient,
        );

  /// The store names from which to (possibly) read/update/create tiles from/in
  ///
  /// Keys represent store names, and the associated [StoreReadWriteBehavior]
  /// represents how that store should be used.
  ///
  /// Stores not included will not be used by default. However,
  /// [otherStoresBehavior] determines whether & how all other unspecified
  /// stores should be used.
  final Map<String, StoreReadWriteBehavior> storeNames;

  /// The behaviour of all other stores not specified in [storeNames]
  ///
  /// `null` means that all other stores will not be used.
  ///
  /// Setting a non-`null` value may reduce performance, as internal queries
  /// will have fewer constraints and therefore be less efficient.
  ///
  /// Also see [FMTCTileProviderSettings.useOtherStoresAsFallbackOnly] for
  /// whether these unspecified stores should only be used as a last resort or
  /// in addition to the specified stores as normal.
  final StoreReadWriteBehavior? otherStoresBehavior;

  /// The tile provider settings to use
  ///
  /// Defaults to the ambient [FMTCTileProviderSettings.instance].
  final FMTCTileProviderSettings settings;

  /// [http.Client] (such as a [IOClient]) used to make all network requests
  ///
  /// Do not close manually.
  ///
  /// Defaults to a standard [IOClient]/[HttpClient].
  final http.Client httpClient;

  /// Allows debugging and advanced logging of internal tile loading mechanisms
  ///
  /// To use, first initialise a [ValueNotifier], like so, then pass it to this
  /// parameter:
  ///
  /// ```dart
  /// final tileLoadingDebugger = ValueNotifier<TileLoadingDebugMap>({});
  /// // Do not use `const {}`
  /// ```
  ///
  /// This notifier will be notified, and the `value` updated, every time a tile
  /// completes loading (successfully or unsuccessfully). The `value` maps
  /// [TileCoordinates] to [TileLoadingDebugInfo]s.
  ///
  /// For example, this could be used to debug why tiles aren't loading as
  /// expected (perhaps when used with [TileLayer.tileBuilder] &
  /// [ValueListenableBuilder]), or to perform more advanced monitoring and
  /// logging than the hit & miss statistics provide.
  final ValueNotifier<TileLoadingDebugMap>? tileLoadingDebugger;

  /// Each [Completer] is completed once the corresponding tile has finished
  /// loading
  ///
  /// Used to avoid disposing of [httpClient] whilst HTTP requests are still
  /// underway.
  ///
  /// Does not include tiles loaded from session cache.
  final _tilesInProgress = HashMap<TileCoordinates, Completer<void>>();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _FMTCImageProvider(
        provider: this,
        options: options,
        coords: coordinates,
        startedLoading: () => _tilesInProgress[coordinates] = Completer(),
        finishedLoadingBytes: () {
          _tilesInProgress[coordinates]?.complete();
          _tilesInProgress.remove(coordinates);
        },
      );

  @override
  Future<void> dispose() async {
    if (_tilesInProgress.isNotEmpty) {
      await Future.wait(_tilesInProgress.values.map((c) => c.future));
    }
    httpClient.close();
    super.dispose();
  }

  /// {@macro fmtc.imageProvider.getBytes}
  Future<Uint8List> getBytes({
    required TileCoordinates coords,
    required TileLayer options,
    Object? key,
    StreamController<ImageChunkEvent>? chunkEvents,
    void Function()? startedLoading,
    void Function()? finishedLoadingBytes,
    bool requireValidImage = false,
  }) =>
      _FMTCImageProvider.getBytes(
        coords: coords,
        options: options,
        provider: this,
        key: key,
        chunkEvents: chunkEvents,
        startedLoading: startedLoading,
        finishedLoadingBytes: finishedLoadingBytes,
        requireValidImage: requireValidImage,
      );

  /// Check whether a specified tile is cached in any of the current stores
  ///
  /// If [storeNames] contains `null` (for example if
  /// [FMTCTileProvider.allStores]) has been used, then the check is for if the
  /// tile has been cached at all.
  Future<bool> checkTileCached({
    required TileCoordinates coords,
    required TileLayer options,
  }) =>
      FMTCBackendAccess.internal.tileExists(
        storeNames: _getSpecifiedStoresOrNull(),
        url: settings.urlTransformer(getTileUrl(coords, options)),
      );

  /// If [storeNames] contains `null`, returns `null`, otherwise returns all
  /// non-null names (which cannot be empty)
  List<String>? _getSpecifiedStoresOrNull() =>
      otherStoresBehavior != null ? null : storeNames.keys.toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProvider &&
          other.storeNames == storeNames &&
          other.headers == headers &&
          other.settings == settings &&
          other.httpClient == httpClient);

  @override
  int get hashCode => Object.hash(storeNames, settings, headers, httpClient);
}

/// Custom override of [Map] that only overrides the [MapView.putIfAbsent]
/// method, to enable injection of an identifying mark ("FMTC")
class _CustomUserAgentCompatMap extends MapView<String, String> {
  const _CustomUserAgentCompatMap(super.map);

  /// Modified implementation of [MapView.putIfAbsent], that overrides behaviour
  /// only when [key] is "User-Agent"
  ///
  /// flutter_map's [TileLayer] constructor calls this method after the
  /// [TileLayer.tileProvider] has been constructed to customize the
  /// "User-Agent" header with `TileLayer.userAgentPackageName`.
  /// This method intercepts any call with [key] equal to "User-Agent" and
  /// replacement value that matches the expected format, and adds an "FMTC"
  /// identifying mark.
  ///
  /// The identifying mark is injected to seperate traffic sent via FMTC from
  /// standard flutter_map traffic, as it significantly changes the behaviour of
  /// tile retrieval, and could generate more traffic.
  @override
  String putIfAbsent(String key, String Function() ifAbsent) {
    if (key != 'User-Agent') return super.putIfAbsent(key, ifAbsent);

    final replacementValue = ifAbsent();
    if (!RegExp(r'flutter_map \(.+\)').hasMatch(replacementValue)) {
      return super.putIfAbsent(key, ifAbsent);
    }
    return this[key] = replacementValue.replaceRange(11, 12, ' + FMTC ');
  }
}
