# Example Application

This package contains a full example application - prebuilt for Android and Windows - showcasing the most important features of this package and it's modules.

{% hint style="info" %}
The example app isn't intended for beginners or as a starting point for a project. It is intended for evaluation purposes, to discover FMTC's capabilities, and how it might be implemented into an app.

To start using FMTC in your own app, please check out the [quickstart.md](quickstart.md "mention") guide instead.
{% endhint %}

## Prebuilt Example Applications

There are prebuilt applications for Android and Windows available on GitHub.

These are automatically built (using GitHub Actions) from the latest available commits every time the source files change, so may include functionality not yet available via pub.dev installation.

{% hint style="success" %}
You can verify that these applications are built directly from the source code, and have not been maliciously modified to included malware, because the committer is always the GitHub Actions Bot, which can be verified by the profile icon linking to a non-profile page.
{% endhint %}

{% embed url="https://github.com/JaffaKetchup/flutter_map_tile_caching/tree/main/prebuiltExampleApplications" %}

### Android

To run the prebuilt Android application on most devices, download the .apk package (from [#prebuilt-example-applications](example-application.md#prebuilt-example-applications "mention")) to your device, then execute it to install it.

After installation, it will appear in the launcher like any other application.

{% hint style="info" %}
The operating system may request permissions to install applications from unknown sources: you must allow this.
{% endhint %}

### Windows

To run the prebuilt Windows application on most devices, download the .exe package (from [#prebuilt-example-applications](example-application.md#prebuilt-example-applications "mention")) to your device, then execute it to install it.

It will require a very simple installation with no administrator privileges required, then it will appear in the Start Menu and search bars like any other application. You can optionally choose to create a desktop shortcut.

{% hint style="info" %}
You may receive security warnings depending on your system setup: these are false positives and occur due to the package being unsigned.
{% endhint %}

### Other Platforms

For other platforms, there are no prebuilt applications.

You'll have to [clone this project](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching.git), open the 'example' directory, and then build for your desired platform using Dart and Flutter as normal.
