# Exporting

The `export()` method copies the stores, along with all necessary tiles, to an archive at the specified location (creating it if non-existent, overwriting it otherwise), in the FMTC (.fmtc) format.

{% hint style="warning" %}
The specified stores must contain at least one tile.
{% endhint %}

{% hint style="warning" %}
Archives are backend specific. They cannot necessarily be imported by a backend different to the one that exported it.
{% endhint %}

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/RootExternal/export.html" %}

```dart
await FMTCRoot.external('~/path/to/file.fmtc').export(['storeName']);
```
