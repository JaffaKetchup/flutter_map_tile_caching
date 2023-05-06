# v6 -> v7 Migration

{% hint style="warning" %}
v7 was left in an broken state due to a package upgrading its version without following semantic versioning, meaning that the pub package resolver could never successfully resolve a working v7 package.

v8 contains all functionality from v7, so should be used.
{% endhint %}

v6 and v7 have significantly different underlying storage systems, and therefore different APIs. Pre-v6 uses a multi-directory filesystem-based structure, whereas v7 uses a multi-database structure based on [Isar](https://isar.dev/).

This page highlights the _biggest changes_ made that will affect the most users - feature additions are not included. Smaller changes are described by in-code documentation or should be self explanatory.

{% hint style="info" %}
Note that the code samples representing the new API do not always include all (new) properties, only those that have changed.
{% endhint %}

{% hint style="success" %}
Don't forget to add and configure the migrator method (`StoreManagement.migrator`) before publishing your app.
{% endhint %}

## Changes

### Initialisation & Root Directory System

Due to the change in the underlying storage system, initialisation has changed to be asynchronous itself, meaning that the previous method of defining the `rootDirectory` was now overly complicated. So the `RootDirectory` system has also been simplified.

{% tabs %}
{% tab title="v6" %}
```dart
FlutterMapTileCaching.initialise(
    await RootDirectory.normalCache,
    // ...
);
final bool isReady = await FMTC.instance.rootDirectory.manage.ready;
```
{% endtab %}

{% tab title="v7" %}
{% code overflow="wrap" %}
```dart
await FlutterMapTileCaching.initialise(
    rootDirectory: null, // Optional for most applications
    // ...
);
// Safely assume that the root directory is ready, until `.manage.delete()` has been called
```
{% endcode %}
{% endtab %}
{% endtabs %}

### Store Management

Some methods have been removed from store management due to limitations in Isar. The deprecation documentation in-code suggests replacements.

### Statistic Watching

Changes have been made, which has improved cross-platform stability and performance. Some properties have changed: consult the documentation for more information. Migration should be self explanatory.

### Global Settings

Validation options have been removed, as any store name (within UTF8) is now acceptable, because the limitations of the filesystem have been removed.

Some Isar database options have been added to manage the database files themselves. These have sensible defaults, although you should check them to make sure they fit your use-case.

### Download Progress

With the introduction of [buffering.md](../bulk-downloading/foreground/buffering.md "mention") for bulk downloading, there are now two additional statistics. The existing statistics `successfulTiles` and `successfulSize` will remain work, but with altered functionality: they now report the number of downloaded, not-necessarily persisted (still in buffer), tiles and size respectivley.

`persistedTiles` and `persistedSize` now report the number of tiles and size that has actually been written to the database.

### Import Collision Handling

Handling collisions with existing stores during imports has gotten easier, with a built-in callback parameter.

## Removals

### Import/Export & Background Downloading Functionality From Base

These functionalities have been separated into their own modules, in order to simplify the installation of this package.

To add this functionality again, see [installation.md](../get-started/installation.md "mention") and [additional-setup.md](../get-started/additional-setup.md "mention").

If you don't use this functionality in your app, you can undo the [additional-setup.md](../get-started/additional-setup.md "mention") instructions related to these modules.

### Statistic Caching

Methods and fields related to statistic caching have been removed, along with the underlying statistic cache system. This is because the new Isar databases are fast enough to calculate statistics, to the point where caching would likely result in reduced performance.
