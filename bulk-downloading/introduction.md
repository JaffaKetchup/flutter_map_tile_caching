# Introduction

This package provides the ability to download areas of maps, known as 'regions' throughout this documentation. There are built in region shapes that even large apps, such as Google Maps, don't have!

Downloading is extremely efficient and fast, and uses multiple threads and isolates to achieve write speeds of hundreds of tiles per second (if the network/server speed allows).

After downloading, tiles are stored in the same place as when Browse Caching, meaning that no extra setup is needed to use them in a map (other than the usual [integration.md](../usage/integration.md "mention")).

{% hint style="warning" %}
Before using FMTC, ensure you comply with the appropriate rules and ToS set by your tile server. Failure to do so may lead to a permenant ban, or any other punishment.

This library and/or the creator(s) are not responsible for any violations you make using this package.

OpenStreetMap's can be [found here](https://operations.osmfoundation.org/policies/tiles): specifically bulk downloading is discouraged, and forbidden after zoom level 13. Other servers may have different terms.
{% endhint %}

## 4 Steps To Downloading

1. [Create a region based on the user's input](regions.md)
2. [Convert that region into a downloadable region](prepare.md)
3. Start downloading that region, either in the [foreground](foreground/) or [background](background/)
4. [Listen for progress events to update your user](foreground/progress.md)

## Available APIs

All APIs listed in this section are children of the `download` getter.

| API Member                                       | Explanation                                   |
| ------------------------------------------------ | --------------------------------------------- |
| [`startForeground()`](foreground/)               | Start a download in the foreground            |
| [`startBackground()`](background/)               | Start a download in the background            |
| [`check()`](prepare.md#checking-number-of-tiles) | Check the number of tiles in a certain region |
| [`cancel()`](cancel-download.md)                 | Cancel any ongoing downloads                  |

## Recovery

The recovery system is designed to support bulk downloading, and provide some form of recovery if the download fails unexpectedly - this might happen if the app crashes, for example.

Read more about the recovery system here:

{% content-ref url="../usage/roots-and-stores/recovery.md" %}
[recovery.md](../usage/roots-and-stores/recovery.md)
{% endcontent-ref %}
