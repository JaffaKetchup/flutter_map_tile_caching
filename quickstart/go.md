# Quickstart

{% hint style="warning" %}
**FMTC is licensed under GPL-v3.**

If you're developing a proprietary (non open-source) application, this affects you and your application's legal right to distribution. For more information, please see [#proprietary-licensing](../#proprietary-licensing "mention").
{% endhint %}

{% hint style="warning" %}
Before using FMTC, ensure you comply with the appropriate rules and ToS set by your tile server. Failure to do so may lead to a permenant ban, or any other punishment.

This library and/or the creator(s) are not responsible for any violations you make using this package.

OpenStreetMap's can be [found here](https://operations.osmfoundation.org/policies/tiles): specifically bulk downloading is discouraged, and forbidden after zoom level 13. Other servers may have different terms.
{% endhint %}

This page guides you through a simple, fast setup of FMTC that just enables basic browse caching, without any of the bells and whistles that you can discover throughout the rest of this documentation.

## 1. [Install](../get-started/installation.md)

Depend on the latest version of the package from pub.dev, then import it into the appropriate files of your project.

{% code title="Console/Terminal" %}
```sh
flutter pub add flutter_map_tile_caching
```
{% endcode %}

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```

## 2. [Initialise](../get-started/initialisation.md)

Perform the startup procedure to allow usage of FMTC's APIs and connect to the underlying systems.

<pre class="language-dart" data-title="main.dart"><code class="lang-dart">import 'package:flutter/widgets.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Future&#x3C;void> main() async {
    WidgetsFlutterBinding.ensureInitialized();   
<strong>    await FlutterMapTileCaching.initialise();
</strong>    // ...
    // runApp(MyApp());
}
</code></pre>

## 3. [Create a store](../usage/roots-and-stores/#without-automatic-creation)

Create an isolated space to store tiles and other information to be accessed by the map and other methods.

<pre class="language-dart" data-title="main.dart"><code class="lang-dart">Future&#x3C;void> main() async {
    WidgetsFlutterBinding.ensureInitialized();   
    await FlutterMapTileCaching.initialise();
<strong>    FMTC.instance('mapStore').manage.create();
</strong>    // ...
    // runApp(MyApp());
}
</code></pre>

## 4. [Connect to 'flutter\_map'](../usage/integration.md)

Enable your `FlutterMap` widget to use the caching and underlying systems of FMTC.

<pre class="language-dart"><code class="lang-dart">import 'package:flutter_map/flutter_map.dart';

TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.example.app',
<strong>    tileProvider: FMTC.instance('mapStore').getTileProvider(),
</strong>    // Other parameters as normal
),
</code></pre>

{% hint style="success" %}
You should now have a basic working implementation of FMTC that caches tiles for you as you browse the map!

There's a lot more to discover, from management to bulk downloading, and from statistics to exporting/importing.
{% endhint %}
