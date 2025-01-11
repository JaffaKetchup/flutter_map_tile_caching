# Root

A root contains statistics about itself and the stores, as well as information for the bulk download [recovery.md](../bulk-downloading/recovery.md "mention") system, and access to the import/export functionality.

Roots are unnamed, and the current root is accessed through `FMTCRoot`:

<pre class="language-dart"><code class="lang-dart"><strong>// final root = FMTCRoot;
</strong>final databaseSize = await FMTCRoot.stats.realSize;
</code></pre>

{% hint style="info" %}
To manage the root, use the methods on the backend.
{% endhint %}

## Statistics

`FMTCRoot.stats` allows access to statistics, as well as listing of all existing stores, and the watching of changes in multiple/all stores.

{% embed url="https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/RootStats-class.html" %}

{% hint style="info" %}
Remember that the `size` and `length` statistics in the root may not be equal to the sum of the same statistics of all available stores, because tiles may belong to many stores, and these statistics do not count any tile multiple times.
{% endhint %}

## Recovery

{% content-ref url="../bulk-downloading/recovery.md" %}
[recovery.md](../bulk-downloading/recovery.md)
{% endcontent-ref %}

## Import/Export

{% content-ref url="../import-export/" %}
[import-export](../import-export/)
{% endcontent-ref %}
