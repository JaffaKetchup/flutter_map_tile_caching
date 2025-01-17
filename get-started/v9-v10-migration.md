# v9 -> v10 Migration

{% hint style="success" %}
v10 focuses on completing the 'tiles-across-stores' functionality from v9, by bringing it to browse caching, which huge amounts of customizability and flexibility.

Check out the CHANGELOG: [https://pub.dev/packages/flutter\_map\_tile\_caching/changelog](https://pub.dev/packages/flutter_map_tile_caching/changelog)! This page only covers breaking changes, not feature additions and fixes.

Please consider donating: [#supporting-me](../#supporting-me "mention")! Any amount is hugely appreciated!
{% endhint %}

## Browse Caching

We recommend following the steps on [integrating-with-a-map.md](../usage/integrating-with-a-map.md "mention") from start to finish to migrate your existing `FMTCTileProvider` to v10, as the API has significant changes, and the steps include new guidance to ensure best practice and performance.

Some changes are highlighted below:

<details>

<summary>Absorbed <code>FMTCTileProviderSettings</code> directly into <code>FMTCTileProvider</code></summary>

The properties within have become properties directly in `FMTCTileProvider`. This also means the automatic global system (where the settings could be set once then used everywhere) has also been removed.

The simplifies the code internals and removes an unnecessary layer of abstraction.

</details>

<details>

<summary>Replaced <code>maxStoreLength</code> with property directly on stores</summary>

It has been replaced with a property on each store itself. It can be set at creation, or changed after, and read at any time:

```dart
await FMTCStore('storeName').manage.create(maxLength: 1000);
await FMTCStore('storeName').manage.setMaxLength(null); // Disable max length
final maxLength = await FMTCStore('storeName').manage.maxLength;
```

This is more suitable for providers now that more than one store may be used, potentially each with a different maximum length.

</details>

<details>

<summary>Replaced <code>obscuredQueryParams</code> with <code>urlTransformer</code></summary>

It has been replaced on the `FMTCTileProvider` with a more flexible custom callback which may perform any processing logic required, and a utility method if the old behaviour is still desired.

To migrate directly, see the example setup: [#two-static-named-stores-with-a-url-transformer](../usage/integrating-with-a-map.md#two-static-named-stores-with-a-url-transformer "mention").

</details>

<details>

<summary>Renamed <code>CacheBehavior</code> with <code>BrowseLoadingStrategy</code></summary>

This has been renamed to fit better with a newly introduced enumerable that work together to configure the tile provider's logic.

(And also, no more US/UK confusion :D)

</details>

## Bulk Downloading

Most of bulk downloading hasn't had any breaking changes, with the major exception of these:

<details>

<summary><code>startForeground</code> now returns two streams</summary>

It now returns one stream of `DownloadProgress`s, and one of the new `TileEvent`s. This means that checks no longer have to be made to ensure a `TileEvent` is not a repeated event (except where using the new feature to retry failed tiles, discussed below), and also means they can be more easily listened to independently.

To migrate, listen to necessary streams seperately.&#x20;

</details>

<details>

<summary>Renovated <code>TileEvent</code> completely</summary>

Properties in v9 were nullable dependent on whether they were available, and this could be checked with `.result` (`TileEventResult`).

`TileEvent` has been split into a tree of classes, which are sealed. This means that the available properties are fully safe and no null-checks need to be made. Switch-case statements and normal `is` checks can be used, which statically changes the type of the `TileEvent` to a subtype appropriately. Each subtype represents a specific outcome of the tile download, and mixes in certain types.

* `SuccessfulTileEvent` is emitted when a tile is successfully downloaded\
  &#xNAN;_&#x52;oot subtype, mixes in `TileEventFetchResponse` (makes the raw fetch response from the server available) and `TileEventImage` (makes tile image available)_
* `SkippedTileEvent` (\*[^1])\
  &#xNAN;_&#x52;oot subtype, mixes in `TileEventImage`_
  * `ExistingTileEvent` is emitted when a tile is skipped because it already exists
  * `SeaTileEvent` is emitted when a tile is skipped because it was a sea tile\
    &#xNAN;_&#x41;lso mixes in `TileEventFetchResponse`_
* `FailedTileEvent` (\*[^2])\
  &#xNAN;_&#x52;oot subtype_
  * `NegativeResponseTileEvent` is emitted when a tile fails because the server did not respond with 200 OK\
    &#xNAN;_&#x4D;ixes in `TileEventFetchResponse`_
  * `FailedRequestTileEvent` is emitted when a tile fails because the request to the server was not made successfully (eligible for retry)

</details>

<details>

<summary>Renamed properties within <code>DownloadProgress</code></summary>

Most are renamed obviously to improve clarity. Some may have had the exact included figures changed.

</details>

[^1]: another abstract type

[^2]: another abstract type
