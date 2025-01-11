# Stores

Stores maintain references to all tiles which belong to it, and also contain customizable metadata and cached statistics.

They are referenced by name, the single argument of `FMTCStore`.

{% hint style="warning" %}
Ensure names of stores are consistent across every access. "Typed"/code-generated stores are not provided, to maintain flexibility.
{% endhint %}

{% hint style="warning" %}
Construction of an `FMTCStore` object does create the underlying store, as this is an asynchronous task. It must be created before it may be used.
{% endhint %}

<pre class="language-dart"><code class="lang-dart"><strong>// final store = FMTCStore('storeName');
</strong>await FMTCStore('storeName').manage.create(); // Creates the store
</code></pre>

## Management

`FMTCStore().manage` allows control over the store and its contents.

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/StoreManagement-class.html" %}

## Statistics

`FMTCStore().stats` allows access to:

* statistics
* retrieval of a recent tile (as an image)
* watching of changes to the store

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/StoreStats-class.html" %}

## Metadata

`FMTCStore().metadata` allows access and control over a simple persistent storage mechanism, designed for use with custom data/properties/fields tied to the store. For example, in some apps, it could store the `BrowseStoreStrategy` or URL template/source.

Data is interpreted in key-value pair form, where both the key and value are `String`s. Internally, the default backend stores it as a flat JSON structure. The metadata is stored directly on the store: if the store is deleted, it is deleted, and an exported store retains its metadata. More advanced requirements will require use of a separate persistence mechanism.

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/StoreMetadata-class.html" %}

{% hint style="info" %}
Remember that `metadata` does not have any effect on internal logic: it is simply an auxiliary method of storing any data that might need to be kept alongside a store.
{% endhint %}
