# ❔ Is FMTC Right For Me?

_In a one word answer: Yes._

FMTC aims to provide all the functionality you will need for advanced offline mapping in your app, and the unique features that will help set your app apart from the competition, in a way that requires little knowledge of the internals of 'flutter\_map' and other caching fundamentals, and little effort from you (for most setups).

However, this doesn't mean there aren't any other options to consider! The flutter\_map documentation gives a good overview of the different types of caching.

{% embed url="https://docs.fleaflet.dev/tile-servers/offline-mapping" %}

In general, there's a few reasons why I wouldn't necessarily recommend using FMTC:

* You're not planning to make use of bulk downloading or import/export functionality
* You don't need the fine grained control of stores (and their many-to-many relationship with tiles that keeps duplication minimal across them)
* You want to ship every user a standardized tileset, and you don't really need other functionality after that point

Although FMTC will still handle all these situations comfortably, other options may be better suited, and/or more lightweight.

**FMTC is an all-in-one solution. It specialises in the functionalities which are difficult and time-consuming to get right (such as bulk downloading), and their integration with the essential function of browse caching, through a clean, unified API, and a clean, decluttered, and fast backend.**

**Other libraries or DIY solutions may not be all-in-one, but they may be all that's required for your app.** Caching alone is not difficult or time consuming to setup yourself, either through a custom `TileProvider` backed by a non-specialised image caching provider such as '[cached\_network\_image](https://pub.dev/packages/cached_network_image)', or the other browse-caching-only flutter\_map plugin '[flutter\_map\_cache](https://pub.dev/packages/flutter_map_cache)' if you need to save even more time at the expense of more external dependencies.

{% hint style="warning" %}
Another consideration for non-GPL-licensed projects is abiding by FMTC's GPL license. This is especially true for proprietary products.

For more information about licensing, please see [proprietary-licensing.md](proprietary-licensing.md "mention").
{% endhint %}

If you're still not sure, please get in touch: [#get-help](./#get-help "mention")! I'm always happy to offer honest guidance :)
