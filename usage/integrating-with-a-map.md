# Integrating With A Map

"Browse caching" occurs as the map loads tiles as the user interacts with it (or it is controlled by a `MapController`).

To inject the browse caching logic into flutter\_map's tile loading process, FMTC provides a custom `TileProvider`: `FMTCTileProvider`.

Setup is quick and easy in many cases, but this guides through every step in the order in which it should be done to ensure best performance and all factors have been considered.

{% hint style="info" %}
Remember that a store can hold tiles from more than one server/template URL.
{% endhint %}

## Walkthrough

{% hint style="success" %}
Before you can get started, make sure you've [initialised FMTC](initialisation.md) & created one or more [Stores](root-and-stores/stores.md)!
{% endhint %}

{% stepper %}
{% step %}
### Choose where to construct the tile provider

Where & how you choose to construct the `FMTCTileProvider` object has a major impact on performance and tile loading speeds, so it's important to get it right.

Minimize reconstructions of this provider by constructing it outside of the `build` method of a widget wherever possible. Because it is not a `const`ant constructor, and it will be in a non-`const`ant context (`TileLayer`), every rebuild will trigger a potentially expensive reconstruction.

However, in many cases, such as where one or more properties (as described in following stages) depends on inherited data (ie. via an `InheritedWidget`, `Provider`, etc.), this is not possible.\
In this case, read the tip in the [API documentation](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/FMTCTileProvider-class.html) carefully. In summary, you should construct as many arguments as possible outside of the `build` method, particularly a HTTP `Client` and any objects or callbacks which do not have a useful equality/hash code themselves.
{% endstep %}

{% step %}
### Choose _which_ stores it will interact with

The tile provider can interact in multiple ways with multiple stores at once, affording maximum flexibility. Defining _how_ it interacts with these stores will be done in following stages, but you first need to define which stores it will interact with.

How exactly you need to define the stores depends on how much flexibility you need:

{% tabs %}
{% tab title="Specified stores with specified strategies" %}
It is more common you will want to interact with just one or a defined set of stores at any one time. In this case, use the default constructor. You'll need to choose _how_ (what strategy) it interacts with each store in following stages.

The parameters you will need to use will depend on how advanced your use-case is, but it will progress in a linear fashion:

1. The mandatory `stores` argument takes a mapping of store names to the strategy to be used for that store.
2. **If** you want to apply another strategy to all _other_ available stores (whose names are not in the `stores` mapping), use the `otherStoresStrategy` argument.
3. **If** you define _that_ strategy, but you still want to disable interaction with some stores altogether, add these stores to the `stores` mapping with associated `null` values. (If `otherStoresStrategy` is not defined, stores mapped to `null` have no difference to if they were not included in the mapping at all.)

{% hint style="success" %}
Ensure that all specified stores exist.
{% endhint %}
{% endtab %}

{% tab title="All stores with one strategy" %}
If you want it to interact with all available stores (those which have been created), all in the same way (see following stages), use the `allStores` named constructor, and that's it! FMTC will efficiently apply the strategy you choose in the next stage across all stores without you needing to track it yourself.

Remember that the provider can also read tiles from multiple stores, so this may not be necessary - but the option is there!
{% endtab %}
{% endtabs %}
{% endstep %}

{% step %}
### Choose _how_ it will interact with the stores

The `BrowseStoreStrategy`s tell FMTC how it should read, update, and create tiles in the store it is associated to.

In the `allStores` constructor, it is passed to `allStoresStrategy` and applied to all available stores (as described in the previous stage).

Otherwise, in the default constructor, one strategy is assigned to each store, plus optionally one to all other available stores (as described in the previous stage).

There are three possible strategies:

* `.read`: only read tiles from the associated store
* `.readUpdate`: read tiles, and also update existing tiles in the associated store, if necessary
* `.readUpdateCreate`: read, update (if necessary), and create tiles in the associated store
{% endstep %}

{% step %}
### Choose the preferred & fallback source for tiles

The `BrowseLoadingStrategy`s (previously known as `CacheBehavior`s) tell FMTC the preferred source for tiles to be loaded from, and how to fallback if that source fails. It is passed to the `loadingStrategy` parameter.

There are three possible priorities:

| Strategy                 | Preferred method | Fallback method |
| ------------------------ | ---------------- | --------------- |
| `.cacheOnly`             | Cache            | _Failure_       |
| `.cacheFirst` \*[^1]     | Cache            | Network (URL)   |
| `.onlineFirst`           | Network (URL)    | Cache           |
| _Standard tile provider_ | _Network (URL)_  | _Failure_       |

The `cacheOnly` strategy essentially disables writing to the cache, and makes the chosen `BrowseStoreStrategy`s above `.read` redundant.

{% hint style="warning" %}
The `onlineFirst` strategy may make tile loading appear slower when not connected to the Internet/network.

This is because the HTTP client may attempt to make the request anyway (Dart does not realise sometimes that the Internet is not available), in which case, the HTTP timeout set in the client must elapse before the tile is retrieved from the cache.
{% endhint %}

<details>

<summary>Customizing the interaction with <code>otherStoresStrategy</code> (if set)</summary>

The `useOtherStoresAsFallbackOnly` parameter concerns the behaviour of FMTC when a tile does not belong to any stores set in the `stores` mapping, but does belong to stores covered by `otherStoresStrategy`.

* If `false` (as default), then the tile will be used without attempting the fallback method.
* If `true`, then the tile will only be used if the fallback method fails.

This is not of concern if the strategy is `onlineFirst`, as if the always-attempted network fetch fails, the tile will always be used from the unspecified store.

</details>

Also see how this strategy influences tile updates in stage 6.
{% endstep %}

{% step %}
### Ensure tiles are resilient to URL changes

To reference (enable correct creation/updating/reading of) tiles, FMTC uses a 'storage-suitable UID' derived from the tile's URL.\
Any one tile from the same server (style, etc. allowing) should have one storage-suitable UID which does not change.

On some servers, it may be acceptable for the UID to be the same as the tile URL. For example, the OpenStreetMap tile server URL for the tile at 0/0/0 will always be `https://tile.openstreetmap.org/0/0/0.png`.\
However, on some servers, the URL may change, but still point to the same desired tile. Consider the following URL: `https://tile.paid.server/0/0/0.png?volatile_key=123`. In this case, the URL requires an API key to retrieve the tile. If the UID was the same as the URL, but the key changes - for example, because it was leaked and refreshed - then FMTC would be unable to reference this tile when it encounters the same URL  with the different key. This would mean the tile could not be read or updated, which may significantly impact your app's functionality.

To fix this, the `urlTransformer` parameter takes a callback which gets passed the tile's real URL, and should return a stable storage-suitable UID. For example, it should remove the offending query parameters.

{% hint style="warning" %}
The `urlTransformer` defined here should usually be the same as the transformer defined for a bulk download. Otherwise, tiles which have been bulk downloaded may not be able to be referenced, for example if an API key changes.

If the `TileLayer` used to start the bulk download uses an `FMTCTileProvider` with a defined `urlTransformer` as the tile provider, it will be used automatically, otherwise the bulk download also takes the `urlTransformer` directly.
{% endhint %}

If the offending part of the URL occurs as in the example above - as part of a query string - FMTC provides a utility callback which can be used as the transformer to remove the offending key & value cleanly.\
`FMTCTileProvider.urlTransformerOmitKeyValues` takes the tile URL as input, as well as a list of keys. It will remove both the key and associated value for each listed key.\
It may also be customized to use a different 'link' ('=') and 'delimiter' ('&') character, and it will remove any `key<link>value` found in the URL, not just from after the '?' character.
{% endstep %}

{% step %}
### Configure tile updates

A tile will be updated in a store if all the following conditions are met:

* [x] The tile already exists in the store
* [x] The `BrowseStoreStrategy` is `.readUpdate` or `.readUpdateCreate`
* [x] The `BrowseLoadingStrategy` is not `.cacheOnly`
* [x] The tile can be fetched successfully from the network/Internet
* [x] _...and if either (or both)..._
  * The `BrowseLoadingStrategy` is `.onlineFirst`
  * **The tile has been flagged for updating**

The `cachedValidDuration` parameter can be used to set an expiry for all tiles written whilst it is set. Once a tile is expired, it will be flagged as needing updating. By default, there is no expiry set.
{% endstep %}

{% step %}
### Configure other parameters

<details>

<summary>Basic hits &#x26; misses statistics (<code>recordHitsAndMisses</code>)</summary>

By default, every tile attempted during browsing records either a hit or miss.

A hit is recorded when a tile is read from the cache without attempting the network in all stores in which the tile exists & were present in the `stores` mapping (and not explicitly set `null`), or in which the tile exists if `otherStoresStrategy` was set.

In every other case, a miss is recorded in all stores present in the `stores` mapping  (and not explicitly set `null`), or in all stores if `otherStoresStrategy` was set.

This information may not be useful or used in many apps, and so it may be disabled by setting it `false`. This will also improve performance (reduce tile loading times and device memory/storage operations). Additionally, more detailed and advanced metrics may be obtained by setting up a `tileLoadingInterceptor` (as below).

</details>

<details>

<summary>Handle tile load failures (<code>errorHandler</code>)</summary>

_This feature is completely standalone to the `TileLayer`'s `errorImage`._

By default, when a tile cannot be loaded, an `FMTCBrowsingError` is thrown containing some information about why the load failed. This is because _something_ must be returned or thrown by internal `ImageProvider`.

However, it is possible to provide an error handler, which gets passed the failure as an argument, and may optionally return bytes (which must be decodable by Flutter). If it does return bytes, the error will not be thrown, and instead the bytes will be displayed in place of the tile image.

</details>

<details>

<summary>Intercept tile load events &#x26; info (<code>tileLoadingInterceptor</code>)</summary>

To track (eg. for debugging and logging) the internal tile loading mechanisms, an interceptor may be used.&#x20;

For example, this could be used to debug why tiles aren't loading as expected (perhaps in combination with `TileLayer.tileBuilder` & `ValueListenableBuilder` as in the example app), or to perform more advanced monitoring and logging than the hit & miss statistics provide.

The interceptor consists of a `ValueNotifier`, which allows FMTC internals to notify & push updates of tile loads, and allows the owner to listen for changes as well as retrieve the latest update (`value`) immediately.\
The object within the `ValueNotifier` is a mapping of `TileCoordinates` to [`TileLoadingInterceptorResult`](https://pub.dev/documentation/flutter_map_tile_caching/10.0.0-dev.7/flutter_map_tile_caching/TileLoadingInterceptorResult-class.html)s.

</details>

{% hint style="info" %}
Stores may also have a `maxLength` defined (the maximum number of tiles that store may hold). This is enforced automatically during browse caching.
{% endhint %}


{% endstep %}

{% step %}
{% hint style="success" %}
And that's it! FMTC will handle everything else behind the scenes.

If you bulk download tiles, they'll be able to be used automatically as well.
{% endhint %}
{% endstep %}
{% endstepper %}

## Examples

### A single store in a simple static configuration

This is the most simple case where one store exists, using the default constructor and no other parameters except a `BrowseLoadingStrategy`.

```dart
class _...State extends State<...> {
  final _tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
    loadingStrategy: BrowseLoadingStrategy.onlineFirst,
  );
  // and if "mapStore" is the only store, this could also be written as
  final _tileProvider = FMTCTileProvider.allStores(
    allStoresStrategy: BrowseStoreStrategy.readUpdateCreate,
    loadingStrategy: BrowseLoadingStrategy.onlineFirst,
  );
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: _tileProvider,
        ),
      ],
    );
  }
}
```

### Two static named stores with a URL transformer

In this case, there are two stores which never change, which use different `BrowseStoreStrategy`s. There is also a `urlTransformer` defined, using the utility method.

```dart
class _...State extends State<...> {
  final _tileProvider = FMTCTileProvider(
    stores: const {
      'store 1': BrowseStoreStrategy.readUpdateCreate,
      'store 2': BrowseStoreStrategy.read,
    },
    urlTransformer: (url) => FMTCTileProvider.urlTransformerOmitKeyValues(
      url: url,
      keys: ['access_key'],
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.paid.server/{z}/{x}/{y}.png?access_key={access_key}',
          userAgentPackageName: 'com.example.app',
          additionalOptions: const {
            'access_key': '123',
          },
          tileProvider: _tileProvider,
        ),
      ],
    );
  }
}
```

### Stores set from a Provider/Selector with a URL transformer

{% hint style="success" %}
Note that the URL transformer callback and HTTP client have been defined outside of the `FMTCTileProvider` constructor (which must lie within the `build` method because it depends on inherited data).

Defining the URL transformer this way instead of an anonymous function ensures that the caching key works correctly, which improves the speed of tile loading.

Defining the HTTP client (although it is technically optional) ensures it remains open even when the provider is being repeatedly reconstructed, which means it does not have to keep re-creating connections to the tile server, improving tile loading speed. Note that it is not closed when the widget is destroyed: this prevents errors when the widget is destroyed whilst tiles are still being loaded, and there is very little potential for memory or performance leaks.
{% endhint %}

```dart
class _...State extends State<...> {
  late final _httpClient = IOClient(HttpClient()..userAgent = null);
  String _urlTransformer(String url) =>
      FMTCTileProvider.urlTransformerOmitKeyValues(
        url: url,
        keys: ['access_key'],
      );
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      children: [
        Selector<GeneralProvider, Map<String, BrowseStoreStrategy?>>(
          selector: (context, provider) => provider.stores,
          builder: (context, stores, _) => 
            TileLayer(
              urlTemplate: 'https://tile.paid.server/{z}/{x}/{y}.png?access_key={access_key}',
              userAgentPackageName: 'com.example.app',
              additionalOptions: const {
                'access_key': '123',
              },
              tileProvider: FMTCTileProvider(
                stores: stores,
                urlTransformer: _urlTransformer,
                httpClient: _httpClient,
              ),
            ),
      ],
    );
  }
}
```

### Using multiple stores alongside `otherStoresStrategy`, and explicitly disabling a store

```dart
class _...State extends State<...> {
  final _tileProvider = FMTCTileProvider(
    stores: const {
      'store 1': BrowseStoreStrategy.readUpdateCreate,
      'store 2': BrowseStoreStrategy.read,
      // 'store 3' implicitly gets `.readUpdate`,
      'store 4': null, // disabled
    },
    otherStoresStrategy: BrowseStoreStrategy.readUpdate,
  );
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: _tileProvider,
        ),
      ],
    );
  }
}
```

[^1]: default
