# Example Application

This package contains a full example application - prebuilt for Android and Windows by GitHub Actions - showcasing the most important features of this package and its modules.

{% hint style="info" %}
The example app isn't intended for beginners or as a starting point for a project. It is intended for evaluation purposes, to discover FMTC's capabilities, and how it might be implemented into an app.

To start using FMTC in your own app, please check out the [quickstart.md](quickstart.md "mention") guide instead.
{% endhint %}

{% hint style="success" %}
The example application pairs perfectly with the testing tile server included in the FMTC project: [testing-tile-server.md](../usage/bulk-downloading/testing-tile-server.md "mention")!
{% endhint %}

## Prebuilt Artifacts

If you can't build from source for your platform, our GitHub Actions CI system compiles the example app to artifacts for Windows and Android, which just require unzipping and installing the .exe or .apk found inside.

{% hint style="info" %}
Note that these artifacts are built automatically from the ['master' branch](https://github.com/fleaflet/flutter_map), so may not reflect the the latest release on pub.dev.
{% endhint %}

{% embed url="https://nightly.link/JaffaKetchup/flutter_map_tile_caching/workflows/main/main" %}
Latest Build Artifacts (thanks [nightly](https://nightly.link/))
{% endembed %}

## Build From Source

If you need to use the example app on another platform, you can build from source, using the 'example' directory of the repository.
