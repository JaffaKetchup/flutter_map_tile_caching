---
description: fmtc_plus_sharing Module
---

# Introduction

{% hint style="success" %}
The [`fmtc_plus_sharing`](https://github.com/JaffaKetchup/fmtc\_plus\_sharing) module is required to use the import/export functionality.

See the [#fmtc\_plus\_sharing-installation-and-setup](../get-started/additional-setup.md#fmtc\_plus\_sharing-installation-and-setup "mention") instructions to add this module.
{% endhint %}

{% hint style="warning" %}
Note that some tile servers, such as Mapbox, forbid the sharing of their cached tiles, but this should still be acceptable as long as a user only imports their own exports (for example, backup purposes).
{% endhint %}

It is possible to [export](exporting.md) an entire store (including tiles and metadata) to a standalone file that can be easily shared and distributed between devices, then [imported](importing.md) on any device.

For example, they can be used to create backup systems, sharing systems, or to distribute a preset package of tiles to all users without worrying about managing IO or managing assets!
