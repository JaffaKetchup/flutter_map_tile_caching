# Bulk Downloading

FMTC provides the ability to bulk download areas of maps in one-shot, known as 'regions'. There are multiple different types/shapes of regions available.

{% hint style="warning" %}
Before using FMTC, especially to bulk download or import/export, ensure you comply with the appropriate restrictions and terms of service set by your tile server. Failure to do so may lead to any punishment, at the tile server's discretion.

This library and/or the creator(s) are not responsible for any violations you make using this package.

For example, OpenStreetMap's tile server forbids bulk downloading: [https://operations.osmfoundation.org/policies/tiles](https://operations.osmfoundation.org/policies/tiles). And Mapbox has restrictions on importing/exporting from outside of the user's own device.

For testing purposes, check out the testing tile server included in the FMTC project: [testing-tile-server.md](testing-tile-server.md "mention").
{% endhint %}

Downloading is extremely efficient and fast, and uses multiple threads and isolates to achieve write speeds of hundreds of tiles per second (if the network/server speed allows). After downloading, no extra setup is needed to use them in a map (other than the usual [integrating-with-a-map.md](../integrating-with-a-map.md "mention")).

## Walkthrough

{% hint style="success" %}
Before you can get started, make sure you've [initialised FMTC](../initialisation.md) & created one or more [Stores](../root-and-stores/stores.md)!
{% endhint %}

{% stepper %}
{% step %}
### Define a region

A region represents a geographical area only, not any of the other information required to start a download.

All types of region inherit from `BaseRegion`.

{% tabs %}
{% tab title="Rectangle" %}
`RectangleRegion`s are defined by a `LatLngBounds`: two opposite `LatLng`s.

```dart
final region = RectangleRegion(
    LatLngBounds(LatLng(0, 0), LatLng(1, 1)),
);
```
{% endtab %}

{% tab title="Circle" %}
`CircleRegion`s are defined by a center `LatLng` and radius _in kilometers_.

```dart
final region = CircleRegion(
    LatLng(0, 0), // Center coordinate
    1, // Radius in kilometers
);
```

If you instead have two coordinates, one in the center, and one on the edge, you can use ['latlong2's `Distance.distance()`](https://pub.dev/documentation/latlong2/latest/latlong2/Distance/distance.html) method, as below:

```dart
final centerCoordinate = LatLng(0, 0); // Center coordinate
final region = CircleRegion(
    centerCoordinate,
    const Distance(roundResult: false).distance(
        centerCoordinate,
        LatLng(1, 1), // Edge coordinate
    ) / 1000; // Convert to kilometers
);
```
{% endtab %}

{% tab title="(Poly)Line" %}
`LineRegion`s are defined by a list of `LatLng`s, and a radius in meters.

This could be used to download tiles along a planned travel route, for example hiking or long-distance driving. Import coordinates from a routing engine, or from a GPX/KML file for maximum integration!

```dart
final region = LineRegion(
    [LatLng(0, 0), LatLng(1, 1), ...], // List of coordinates
    1000, // Radius in meters
);
```

{% hint style="warning" %}
This region may generate more tiles than strictly necessary to cover the specified region. This is due to an internal limitation with the region generation algorithm, which uses (rotated) rectangles to approximate the actual desired shape.
{% endhint %}

{% hint style="warning" %}
This type of region may consume more memory/RAM when generating tiles than other region types.
{% endhint %}
{% endtab %}

{% tab title="Custom Polygon" %}
`CustomPolygonRegion`s are defined by a list of `LatLng`s defining the outline of a [simple polygon](https://en.wikipedia.org/wiki/Simple_polygon).

```dart
final region = CustomPolygonRegion(
    [LatLng(0, 0), LatLng(1, 1), ...], // List of coordinates
);
```

{% hint style="warning" %}
Polygons should not contain self-intersections. These may produce unexpected results.

Holes are not supported, however multiple `CustomPolygonRegion`s may be downloaded at once using a `MultiRegion`.
{% endhint %}
{% endtab %}

{% tab title="Multi" %}
`MultiRegion`s are defined by a list of multiple `BaseRegion`s (which may contain more nested `MultiRegion`s).

When downloading, each sub-region specified is downloaded consecutively (to ensure that any `start` & `end` tile range defined is respected consistently.

{% hint style="warning" %}
Regions which overlap will still have the overlapping tiles downloaded for each region.

Multi region's advantage is that it reduces the number of costly setup and teardown operations. It also means that statistic measuring applies over all sub-regions, so it does not need to be managed indepedently.
{% endhint %}
{% endtab %}
{% endtabs %}

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/BaseRegion-class.html" %}

It is also possible to reconstruct the region from a `RecoveredRegion`: [#recoveredregion](recovery.md#recoveredregion "mention").
{% endstep %}

{% step %}
### Add information to make the region downloadable

`BaseRegion`s must be converted to `DownloadableRegion`s before they can be used to download tiles.

These contain the original `BaseRegion`, but also some other information necessary for downloading, such as zoom levels and URL templates.

```dart
final downloadableRegion = region.toDownloadable(
    minZoom: 1,
    maxZoom: 18,
    options: TileLayer(
        urlTemplate: '<your tile server>',
        userAgentPackageName: 'com.example.app',
    ),
),
```

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/BaseRegion/toDownloadable.html" %}

{% hint style="success" %}
The `TileLayer` passed to the `options` parameter must include both a `urlTemplate` (or WMS configuration) and a `userAgentPackageName`, unless it is only being used to `check` the number of tiles in the region.
{% endhint %}
{% endstep %}

{% step %}
### (Optional) Count the number of tiles in the region

Before continuing to downloading the region, use `countTiles()` to count the number of tiles it will attempt to download. This is accessible through `FMTCStore().download`.

The method takes the `DownloadableRegion` generated above, and will return an `int` number of tiles. For larger regions, this may take a few seconds.

{% hint style="warning" %}
This figure will not take into account any skipped sea tiles or skipped existing tiles, as those are handled at the time of download.
{% endhint %}
{% endstep %}

{% step %}
### Configure and start the download

To start the download, use the `startForeground` method on the existing store you wish to download to:

<pre class="language-dart"><code class="lang-dart">final (:downloadProgress, :tileEvents) =
<strong>  const FMTCStore('mapStore').download.startForeground(
</strong>    ...
  );
</code></pre>

There are many options available to customize the download, which are described fully in the API reference:

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/StoreDownload/startForeground.html" %}

The download starts as soon as the method is called; it does not wait for listeners.
{% endstep %}

{% step %}
### Monitor the download outputs

Listening to the output streams of the download is something most apps will want to do, to display information to the user (unless operating in a headless mode or in the background).

There are two output streams returned as a record.\
One stream emits events that contain information about the download as a whole, whilst the other stream independently emits an event after the fetch/download of each tile in the region is attempted. See the API documentation for information on the exact emission frequencies of each stream.\
These are returned separately as the first stream emits events more frequently than the second, and this prevents tile events from needed to be repeated\*.

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/DownloadProgress-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/TileEvent-class.html" %}

{% hint style="warning" %}
An emitted `TileEvent` may refer to a tile for which an event has been emitted previously.

See the API documentation for more information.
{% endhint %}
{% endstep %}

{% step %}
### (Optional) Control the download

Listening, pausing, resuming, or cancelling subscriptions to the output streams will not start, pause, resume, or cancel the download. It will only change whether the download emits updates.

Instead, there are methods available to control the download itself.

#### Pause/Resume

If your user needs to temporarily pause the download, with the ability to resume it at some point later (within the same app session), use `pause` and `resume`.

Pausing does not interrupt any tiles that are being downloaded when `pause` is invoked. Instead, the download will pause after the tile has been downloaded. `pause`'s returned `Future` completes when the download has actually paused (or after `resume` is called whilst still pausing).

Pausing also does not cause the buffer to be flushed (if buffering is in use).

If listening to the `DownloadProgress` stream, an event will be emitted when pausing and resuming.

Use `isPaused` to check whether the download is currently paused.

#### Cancel

If your user needs to stop the download entirely, use `cancel`.

Cancelling does not interrupt any tiles that are being downloaded when `cancel` is invoked. The returned future completes when the download has stopped and been cleaned-up.

Any buffered tiles are written to the store before the future returned by `cancel` is completed.

It is safe to use `cancel` after `pause` without `resume`ing first.
{% endstep %}
{% endstepper %}

## Examples
