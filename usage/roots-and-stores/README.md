# Using Roots & Stores

## How It Works

FMTC uses Roots and Stores to structure it's data. Previously, these represented actual directories (hence the reference to directories within the codebase), but now they just represent [Isar](https://isar.dev/) databases.

There is usually only one root (formed of a directory and some miscellaneous databases) per application, which contains multiple stores (formed of a single database holding a descriptor, multiple tiles, and [metadata](metadata.md)).

## Chaining

Once you can access `FlutterMapTileCaching.instance` after [initialisation.md](../../get-started/initialisation.md "mention"), chaining of methods and accessors is used to access functionality.

1. Base Chains are used as an intermediate step to access functionality on Roots and Stores
2. Additional Chains are added to Base Chains to reach the actual functionality.

### Base Chains

To get the Root, chain on `rootDirectory` (the name of the accessor is a remnant leftover from previous versions).

```dart
FlutterMapTileCaching.instance.rootDirectory;
```

To get a Store, there are two possible methods. FMTC does not use code generation, so store names are flexible, and so use `String`s to access the Store.

{% tabs %}
{% tab title="Without Automatic Creation" %}
{% hint style="success" %}
This is the recommended method. Always use this method where possible.
{% endhint %}

`call()`/`()` gets a `StoreDirectory` by the name inside the parentheses.

Note that the store will not be automatically created once accessed, as this requires asynchronous tasks, so it is important to create the store manually (if necessary).

<pre class="language-dart"><code class="lang-dart"><strong>final store = FlutterMapTileCaching.instance('storeName');
</strong>await store.manage.create(); // Create the store if necessary
</code></pre>

{% hint style="info" %}
Examples in this documentation will usually assume that the stores are already created/ready.
{% endhint %}
{% endtab %}

{% tab title="With Automatic Synchronous Creation" %}
{% hint style="warning" %}
This method is not recommended, for the reasons listed below. Prefer using [#without-automatic-creation](./#without-automatic-creation "mention") wherever possible.

* It is synchronous and therefore blocks the main thread
* It results in hard to trace code, as the creation calls are no longer obvious
* It encourages minimizing accesses to increase performance, which is against the philosophy of the chaining strategy
{% endhint %}

`[]` gets a `StoreDirectory` by the name inside the parenthesis.

Note that the store will be automatically created once accessed, although it will be done synchronously in a way that blocks the main thread.

```dart
final store = FlutterMapTileCaching.instance['storeName'];
```
{% endtab %}
{% endtabs %}

### Additional Chains

After this, you can chain any of the following members/accessors (each will be accessible on a Root, a Store, or both).

{% hint style="success" %}
Prefer using asynchronous versions of sub-methods where possible, as these won't block the UI thread.

If running inside an isolate, or blocking the UI thread doesn't matter, use the synchronous versions wherever possible, as they have slightly better performance.
{% endhint %}

{% content-ref url="../integration.md" %}
[integration.md](../integration.md)
{% endcontent-ref %}

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th data-type="select" data-multiple></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><code>manage</code></td><td></td><td>Control, modify, and configure an actual structure ('physical' directory or database) itself</td><td><a href="management.md">management.md</a></td></tr><tr><td><code>stats</code></td><td></td><td>Retrieve statistics about a structure (Root or Store) itself</td><td><a href="statistics.md">statistics.md</a></td></tr></tbody></table>

<table data-view="cards"><thead><tr><th></th><th data-type="select" data-multiple></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><code>recovery</code></td><td></td><td>Recover failed bulk downloads, and prepare them to restart</td><td><a href="recovery.md">recovery.md</a></td></tr><tr><td><code>migrator</code></td><td></td><td>Migrate the incompatible file/directory structure of a previous version</td><td><a href="http://localhost:5000/s/etKuLqkz5OWV0AkZjLDp/usage/roots-and-stores/migrator">Migrator</a></td></tr><tr><td><code>import</code></td><td></td><td>Import and prepare a store from a previously exported archive file</td><td><a href="../../import-and-export/importing.md">importing.md</a></td></tr><tr><td><code>download</code></td><td></td><td>Prepare, start, and manage a store's bulk downloads</td><td><a href="../../bulk-downloading/introduction.md">introduction.md</a></td></tr><tr><td><code>metadata</code></td><td></td><td>A simple key-value pair store designed for storing simple, store related information</td><td><a href="metadata.md">metadata.md</a></td></tr><tr><td><code>export</code></td><td></td><td>Export a store to an archive file, for future importing</td><td><a href="../../import-and-export/exporting.md">exporting.md</a></td></tr></tbody></table>

{% hint style="info" %}
Looking to modify the underlying databases youself?

This is not recommended, as they are carefully crafted to work with FMTC internal state. But, if you've read through the FMTC code and understand it, and you need to, you may import the internal APIs usually intended for modules.

* Import 'fmtc\_module\_api.dart' from the same package
* Install [Isar](https://isar.dev/)
{% endhint %}
