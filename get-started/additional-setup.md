# Additional Setup

## `flutter_map` Installation & Setup

You must make sure you follow `flutter_map`'s installation **and** additional setup instructions.

{% embed url="https://docs.fleaflet.dev/getting-started/installation" %}

## [`fmtc_plus_background_downloading`](https://github.com/JaffaKetchup/fmtc\_plus\_background\_downloading) Installation & Setup

{% hint style="warning" %}
This module is only supported on Android.
{% endhint %}

To install this module, follow the [installation.md](installation.md "mention") instructions for this package.

### Background Processes

Add the following to 'android\app\src\main\AndroidManifest.xml' and any other manifests:

<pre class="language-diff" data-title="AndroidManifest.xml"><code class="lang-diff"> &#x3C;manifest xmlns:android="http://schemas.android.com/apk/res/android" package="packageName">
+    &#x3C;uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
+    &#x3C;uses-permission android:name="android.permission.WAKE_LOCK" />
+    &#x3C;uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<strong> &#x3C;application android:label="appName" android:icon="appIcon">
</strong></code></pre>

This will allow the application to acquire the necessary permissions (should the user allow them at runtime) to a background process.

* `FOREGROUND_SERVICE`: allows the application to start a foreground service - a type of Android service that can run in the background, as long as the application isn't force stopped.
* `WAKE_LOCK`: allows the background process (technically foreground service) to run even when the device is locked/asleep. Also allows the acquisition of a WiFi lock.
* `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (must be requested at runtime): assists with the background process not being killed by the system.

### Notification Support

Background downloading needs to show notifications, which requires a 3rd party package. See it's installation/setup instructions:

{% embed url="https://pub.dev/packages/flutter_local_notifications#-android-setup" %}

## [`fmtc_plus_sharing`](https://github.com/JaffaKetchup/fmtc\_plus\_sharing) Installation & Setup

To install this module, follow the [installation.md](installation.md "mention") instructions for this package.

### Android (11+)

Please follow these additional instructions for supporting Android versions above 11 and building for release:

{% embed url="https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup#android" %}

### iOS

{% hint style="info" %}
Unfortunately, I do not have the hardware to test this library on Apple platforms. If you find issues, please report them!
{% endhint %}

_It is unknown whether this setup is needed in all cases, so it is recommended to follow these only when you receive errors during building your app._

Some developers may have issues when releasing the app or uploading to TestFlight - see [issue #69](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching/issues/69) for the first report of this problem. This is due to some of this library's dependencies on platform plugins.

*   Annotate that access is not needed to the Media, Audio, and Documents directories - this package uses only custom file types. Add these lines to your Podfile just before `target 'Runner' do`.

    {% code title="Podfile" %}
    ```
    Pod::PICKER_MEDIA = false
    Pod::PICKER_AUDIO = false
    Pod::PICKER_DOCUMENT = false
    ```
    {% endcode %}
* Add `UIBackgroundModes` capability with the `fetch` and `remote-notifications` keys to Xcode, to describe why your app needs to access background tasks - in this case to bulk download maps in the background.
