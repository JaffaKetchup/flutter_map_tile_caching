# Root & Stores

FMTC uses a _root_ and _stores_ to structure its data. In general, a single root exists (which uses a single [backend](../initialisation.md#backends)), which contains multiple named stores. Cached tiles can belong to multiple stores, which reduces duplication and maximizes flexibility.

{% hint style="info" %}
The structures use the ambient backend when a method is invoked on it, not at construction time.

Therefore, it is possible to construct an `FMTCStore`/`FMTCRoot` before initialisation, but 'using' any methods on it will throw `RootUnavailable`.
{% endhint %}
