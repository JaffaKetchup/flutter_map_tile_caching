---
description: Available since v7
---

# Buffering

{% hint style="info" %}
Buffering reduces the total download time, at the expense of increased memory usage.
{% endhint %}

## Without Buffering

Without buffering, every tile is written directly to the database before continuing to the next one (within each simultaneous thread). This requires a write transaction for every tile, which are relatively slow. Without buffering, the database write speed is _usually_ the limiting factor in the download speed.

## With Buffering

To avoid this problem, buffering can be used. Tiles are written to an intermediate buffer before being written to the database, in bulk. This means a transaction is only needed for every bulk write operation, which can lead to huge speed improvements (>2x is possible). However, there are two major cons that you should consider before implementing this in your application:

* **Memory usage increases significantly**\
  When in use, the Memory usage graph within DevTools will likely look like a sawtooth wave. The peak memory usage may be too high for some devices, so you should consider your audience.
* **An app crash can lead to data loss**\
  Tiles in the buffer will be lost in the event of an app crash, meaning their download will have been wasted. Tiles that have been written previously will not be lost.

It may be appropriate to leave the decision up to each user individually. In this case, ensure you thoroughly explain these cons to the user, to allow them to make an informed decision. Alternatively, you might make a decision based on the platform. Desktop platforms are likely to have enough RAM capable of holding the buffer, whereas some older mobile devices may struggle.

## Using Buffering

Buffering is disabled by default, and can be enabled in the `startForeground` method call (the property is not part of the `DownloadableRegion`).

{% hint style="info" %}
Buffering is not supported by background downloading, as maximizing speed isn't usually a priority for background downloads.
{% endhint %}

Buffering can be defined by one of two types of limit, shown below. Neither has a disadvantage in terms of performance, but memory allows finer grain control, at the expense of being less obvious to the user.

* Memory (buffer bytes size)
* Tiles (buffer length)
