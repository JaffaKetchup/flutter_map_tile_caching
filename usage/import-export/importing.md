# Importing

The `import()` method copies the specified archive to a temporary location, then opens it and extracts the specified stores (or all stores if none are specified) & all necessary tiles, merging them into the in-use database. The specified archive must exist, must be valid, and should contain all the specified stores, if applicable.

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/RootExternal/import.html" %}

There is no support for directly overwriting the in-use database with the archived database, but this may be performed manually while FMTC is uninitialised.

{% hint style="warning" %}
There must be enough storage space available on the device to duplicate the entire archive, and to potentially grow the in-use database.

This is done to preserve the original archive, as this operation writes to the temporary archive. The temporary archive is deleted after the import has completed.
{% endhint %}

```dart
final importResult =
    await FMTCRoot.external('~/path/to/file.fmtc').import(['storeName']);
```

The returned value is complex. See the API documentation for more details:

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/ImportResult.html" %}

## Conflict Resolution Strategies

If an importing store has the same name as an existing store, a conflict has occurred, because stores must have unique names. FMTC provides 4 resolution strategies:

* `skip`\
  Skips importing the store
* `replace`\
  Deletes the existing store, replacing it entirely with the importing store
* `rename`\
  Appends the current date and time to the name of the importing store, to make it unique
* `merge`\
  Merges the two stores' tiles and metadata together

In any case, a conflict between tiles will result in the newer (most recently modified) tile winning (it is assumed it is more up-to-date).

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/ImportConflictStrategy.html" %}

## List Stores

If the user must be given a choice as to which stores to import (or it is helpful to know), and it is unknown what the stores within the archive are, the `listStores` getter will list the available store names without performing an import.

{% hint style="warning" %}
The same storage pitfalls as `import` exist. `listStores` must also duplicate the entire archive.
{% endhint %}

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/RootExternal/listStores.html" %}
