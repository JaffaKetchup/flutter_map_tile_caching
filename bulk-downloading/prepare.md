# 2⃣ Prepare For Downloading

{% hint style="warning" %}
Before using FMTC, ensure you comply with the appropriate rules and ToS set by your tile server. Failure to do so may lead to a permenant ban, or any other punishment.

This library and/or the creator(s) are not responsible for any violations you make using this package.

OpenStreetMap's can be [found here](https://operations.osmfoundation.org/policies/tiles): specifically bulk downloading is discouraged, and forbidden after zoom level 13. Other servers may have different terms.
{% endhint %}

[`BaseRegions`](regions.md) must be converted to `DownloadableRegions` before they can be used to download tiles.

These contain the original `BaseRegion`, but also some other information necessary for downloading, such as zoom levels and URL templates.

See this basic example:

```dart
final downloadable = region.toDownloadable(
    1, // Minimum Zoom
    18, // Maximum Zoom
    TileLayer(
        // Use the same `TileLayer` as in the displaying map, but omit the `tileProvider`
        urlTemplate: 'https://api.mapbox.com/styles/v1/jaffaketchup/cle0ehaiz00j101qqr14f8mm3/tiles/256/{z}/{x}/{y}@2x',
        userAgentPackageName: 'com.example.app',
    ),
    // Additional parameters if necessary
),
```

## Additional Parameters

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/BaseRegion/toDownloadable.html" %}

### Sea Tile Removal

By not storing pure tiles of sea, we can save a bunch of space on the user's device with every download. But how to do this?

Well, this package does it by analysing the bytes of the tile and checking if it's identical to a sample taken at lat/lng 0, 0 (Null Island) with zoom level 17. This tile should always be sea, and therefore any matching tile must also be sea.

In this way, we can delete tiles after we've checked them, if they are indeed sea. This method also means that tiles with ferry paths and other markings remain safe.

{% hint style="info" %}
Sea Tile Removal does not reduce time or data consumption. Every tile must still be downloaded to check it.
{% endhint %}

## Checking Number Of Tiles

Before downloading the region, you can count the number of tiles it will attempt to download. This is done by the `check()` method.

The method takes the `DownloadableRegion` generated above, and will return an `int` number of tiles.
