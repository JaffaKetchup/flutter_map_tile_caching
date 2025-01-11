# Recovery

`RootRecovery`, accessed via `FMTCRoot.recovery`, allows access to the bulk download recovery system, which is designed to allow rescue (salvation and restarting) of failed downloads when they crashed due to an unexpected event.

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/RootRecovery-class.html" %}

{% code fullWidth="false" %}
```dart
// List all recoverable regions, and whether each one has failed
await FMTCRoot.recovery.recoverableRegions; 
// List all failed downloads
await FMTCRoot.recovery.recoverableRegions.failedOnly; 
// Retrieve a specific recoverable region by ID
await FMTCRoot.recovery.getRecoverableRegion();
// Safely remove the specified recoverable region
await FMTCRoot.recovery.cancel(); 
```
{% endcode %}

## `RecoveredRegion`

`RecoveredRegion`s are wrappers containing recovery & some downloadable region information, around a `DownloadableRegion`.

Once a `RecoveredRegion` has been retreived, it contains the original `BaseRegion` in the `region` property.

To create a `DownloadableRegion` using the other available information with a provided `TileLayer`, use `toDownloadable`.

{% hint style="success" %}
A `RecoveredRegion` (and a `DownloadableRegion` generated from it) will point to only any remaining, un-downloaded tiles from the failed download.

The `start` tile will be adjusted from the original to reflect the progress of the download before it failed, meaning that tiles already successfully cached (excluding buffered) will not be downloaded again, saving time and network transfers.\
The `end` tile will be either the original, or the maximum number of tiles normally in the region (which will have no resulting difference than `null`, but allows for a quick estimate of the number of remaining tiles to be made without needing to re`check` the entire region).
{% endhint %}
