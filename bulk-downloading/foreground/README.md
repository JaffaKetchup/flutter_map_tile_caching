# 3⃣ Start In Foreground

{% hint style="warning" %}
Before using FMTC, ensure you comply with the appropriate rules and ToS set by your tile server. Failure to do so may lead to a permenant ban, or any other punishment.

This library and/or the creator(s) are not responsible for any violations you make using this package.

OpenStreetMap's can be [found here](https://operations.osmfoundation.org/policies/tiles): specifically bulk downloading is discouraged, and forbidden after zoom level 13. Other servers may have different terms.
{% endhint %}

```dart
FMTC.instance('storeName').download.startForeground();
```

To start downloading tiles, you must [progress.md](progress.md "mention"), even if you do not plan to use the [#available-statistics](progress.md#available-statistics "mention").

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/DownloadManagement/startForeground.html" %}
