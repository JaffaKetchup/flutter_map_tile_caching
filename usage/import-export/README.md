# Import/Export

FMTC allows stores (including all necessary tiles and metadata) to be exported to an 'archive'/a standalone file, then imported on the same or a different device!

{% hint style="warning" %}
Before using FMTC, especially to bulk download or import/export, ensure you comply with the appropriate restrictions and terms of service set by your tile server. Failure to do so may lead to any punishment, at the tile server's discretion.

This library and/or the creator(s) are not responsible for any violations you make using this package.

For example, OpenStreetMap's tile server forbids bulk downloading: [https://operations.osmfoundation.org/policies/tiles](https://operations.osmfoundation.org/policies/tiles). And Mapbox has restrictions on importing/exporting from outside of the user's own device.

For testing purposes, check out the testing tile server included in the FMTC project: [testing-tile-server.md](../bulk-downloading/testing-tile-server.md "mention").
{% endhint %}

{% hint style="info" %}
FMTC does not support exporting tiles to a raw Z/X/Y directory structure with image files that can be read by other programs.
{% endhint %}

For example, this can be used to create backup systems to allow users to store maps for later off-device, sharing/distribution systems, or to distribute a preset package of tiles to all users without worrying about managing IO or managing assets, and still allowing users to update their cache afterward!

***

External functionality is accessed via `FMTCRoot.external('~/path/to/file.fmtc')`.

The path should only point to a file. When used with `export`, the file does not have to exist. Otherwise, it should exist.

{% hint style="warning" %}
The path must be accessible to the application. For example, on Android devices, it should not be in external storage, unless the app has the appropriate (dangerous) permissions.

On mobile platforms (/those platforms which operate sandboxed storage), it is recommended to set this path to a path the application can definitely control (such as app support), using a path from 'package:path\_provider', then share it somewhere else using the system flow (using 'package:share\_plus').
{% endhint %}
