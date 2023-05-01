# flutter\_map Integration

Stores also have the method `getTileProvider()`. This is the point of integration with flutter\_map, providing browse caching through a custom image provider, and can be used as so:

```dart
import 'package:flutter_map/flutter_map.dart';

TileLayer(
    // urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    // userAgentPackageName: 'com.example.app',
    tileProvider: FMTC.instance('storeName').getTileProvider(),
    // Other parameters as normal
),
```

## Tile Provider Settings

This method (and others) optionally take a `FMTCTileProviderSettings`. These configure the behaviour of the tile provider. Defaults to the settings specified in the [global-settings.md](global-settings.md "mention"), or the package default (see table below) if that is not specified.

`FMTCTileProviderSettings` can take the following arguments:

<table data-card-size="large" data-view="cards"><thead><tr><th>Parameter</th><th>Description</th><th>Default</th></tr></thead><tbody><tr><td><code>behavior</code>: <a href="integration.md#cache-behavior"><code>CacheBehavior</code></a></td><td>Determine the logic used during handling storage and retrieval of browse caching</td><td><code>CacheBehavior.cacheFirst</code></td></tr><tr><td><code>cachedValidDuration</code>: <code>Duration</code></td><td>Length of time a tile remains valid, after which it must be fetched again (ignored in <code>onlineFirst</code> mode)</td><td><code>const Duration(days: 16)</code></td></tr><tr><td><code>maxStoreLength</code>: <code>int</code></td><td>Maximum number of tiles allowed in a cache store (deletes oldest tile)</td><td><code>0</code>: disabled</td></tr><tr><td><code>obscuredQueryParams</code>: <code>List&#x3C;String></code></td><td>See <a data-mention href="integration.md#obscuring-query-parameters">#obscuring-query-parameters</a></td><td><code>[]</code>: empty</td></tr></tbody></table>

### Cache Behavior

This enumerable contains 3 values, which are used to dictate which logic should be used to store and retrieve tiles from the store.

| Value         | Explanation                                                                                                                             |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `cacheFirst`  | <p>Get tiles from the local cache if possible.</p><p>Only uses the Internet if it doesn't exist, or to update it if it has expired.</p> |
| `onlineFirst` | <p>Get tiles from the Internet if possible.</p><p>Updates every cached tile every time it is fetched (ignores expiry).</p>              |
| `cacheOnly`   | <p>Only get tiles from the local cache, and throw an error if not found.</p><p>Recommended for dedicated offline modes.</p>             |

### Obscuring Query Parameters

{% hint style="success" %}
This feature was added in v7.1.1. Upgrade to that version or later to use this functionality.

A backport of this functionality to v6 is also available - see [this branch on GitHub](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching/tree/v6-backporting), and install it through GitHub: [#from-github.com](../get-started/installation.md#from-github.com "mention").
{% endhint %}

If you've got a value (such as a token or a key) in the URL's query parameters (the key-value pairs list found after the '?') that you need to keep secret or that changes frequently, make use of `obscuredQueryParams`.

Pass it the list of query keys who's values need to be removed/omitted/obscured in storage. For example, 'api\_key' would remove the 'api\_key', and any other characters until the next key-value pair, or the end of the URL, as seen below:

<pre><code>https://tile.myserver.com/{z}/{x}/{y}?api_key=001239876&#x26;mode=dark
<strong>https://tile.myserver.com/{z}/{x}/{y}?&#x26;mode=dark
</strong></code></pre>

{% hint style="info" %}
Since v3, FMTC relies on URL equality to find tiles within a store during browsing. This method is therefore necessary in cases where a token changes periodically.
{% endhint %}

## Check If A Tile Is Cached

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/FMTCTileProvider/checkTileCached.html" %}
