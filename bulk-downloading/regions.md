# 1⃣ Create A Region

Creating regions is designed to be easy for the user and you (the developer).

The [example-application.md](../get-started/example-application.md "mention") contains a great way you might want to allow your users to choose a region to download, and it shows how to use Provider to share a created region and the number of approximate tiles it has to a download screen.

## Types Of Region

All regions (before conversion to `DownloadableRegion`) implement `BaseRegion`.

{% tabs %}
{% tab title="Rectangle" %}
The most basic type of region, defined by two North West and South East coordinates that create a `LatLngBounds`.

```dart
final region = RectangleRegion(
    LatLngBounds(
        LatLng(), // North West
        LatLng(), // South East
    ),
);
```

{% hint style="info" %}
Skewed parallelograms (rectangles with a 3rd control point) or rotated rectangles are not currently supported
{% endhint %}
{% endtab %}

{% tab title="Circle" %}
A more advanced type of region, defined by a center coordinate and radius (in kilometers).

```dart
final region = CircleRegion(
    LatLng(), // Center
    0, // KM Radius
);
```

If you have two coordinates, one center, and one on the edge of the circle you want, you can use ['latlong2's `Distance.distance()`](https://pub.dev/documentation/latlong2/latest/latlong2/Distance/distance.html) method, as below:

```dart
final region = CircleRegion(
    LatLng(), // Center
    const Distance(roundResult: false).distance(
        LatLng(), // Center
        LatLng(), // Edge Coord
    ) / 1000; // Convert to KM
);
```
{% endtab %}

{% tab title="Line" %}
The most advanced type of region, defined by a list of coordinates and radius (in meters).

```dart
final region = LineRegion(
    [LatLng(), LatLng(), ...], // Series of coordinates
    0, // M Radius
);
```
{% endtab %}
{% endtabs %}

After you've created your region, you can convert it to a drawable polygon (below), or [convert it to a `DownloadableRegion`](prepare.md) ready for downloading.

## Converting To Drawable Polygons

All `BaseRegions` can be drawn on a map with minimal effort from you or the user, using `toDrawable()`.

Internally, this uses the `toOutline(s)` method to generate the points forming the `Polygon`, then it places this/these polygons into a `PolygonLayer`.
