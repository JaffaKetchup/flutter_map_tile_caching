# Installation

{% hint style="warning" %}
**FMTC is licensed under GPL-v3.**

If you're developing an application that isn't licensed under GPL, this affects you and your application's legal right to distribution. For more information, please see [proprietary-licensing.md](../proprietary-licensing.md "mention").
{% endhint %}

{% hint style="success" %}
Looking to start using FMTC in your project? Check out the [quickstart.md](quickstart.md "mention") guide!
{% endhint %}

## Install

{% tabs %}
{% tab title="from pub.dev" %}
For the latest stable release, depend on the package as you normally would by adding it to your pubspec.yaml manually or using:

```sh
flutter pub add flutter_map_tile_caching
```
{% endtab %}

{% tab title="from GitHub directly" %}
To depend on potentially unstable commits from a branch (the commits on main usually represent stable releases), for development or testing, follow [#from-pub.dev](installation.md#from-pub.dev "mention"), then add the following lines to your pubspec.yaml file under the `dependencies_override` section:

{% code title="pubspec.yaml" %}
```yaml
dependency_overrides:
    flutter_map_tile_caching:
        git:
            url: https://github.com/JaffaKetchup/flutter_map_tile_caching.git
            # ref: a commit hash, branch name, or tag (otherwise defaults to master)
```
{% endcode %}
{% endtab %}
{% endtabs %}

Then, depending on the platforms you are developing for, you may need to follow ObjectBox's installation instructions for your platform (which can be found originally [here](https://docs.objectbox.io/getting-started), under the Flutter tab):

{% tabs %}
{% tab title="Android" %}
Try building the app - it might just work, especially if you are using other plugins in your app!

<details>

<summary>If it does not build successfully</summary>

If the error message seems to indicate that the "Android NDK" version needs to be higher, follow the instructions.

Usually this involves the following change to your app-level build.gradle(.kts) config:

<pre class="language-diff" data-title="android/app/build.gradle(.kts)"><code class="lang-diff">android {
    namespace = "*"
    compileSdk = flutter.compileSdkVersion
-   ndkVersion = flutter.ndkVersion
<strong>+   ndkVersion = &#x3C;the version specified at the end of the error log>
</strong>
    ...
}
</code></pre>

</details>
{% endtab %}

{% tab title="macOS" %}
macOS apps may need to target macOS 10.15. In your Podfile, change the platform and in the `Runner.xcodeproj/project.pbxproj` file, update `MACOSX_DEPLOYMENT_TARGET`.

***

To enable your app to run in sandboxed mode (which is a requirement for most applications), you'll need to specify an application group. Follow these instructions:

1. Check all `macos/Runner/*.entitlements` files contain a section with the group ID
2.  If necessary, change the string value to the `DEVELOPMENT_TEAM` you can find in your Xcode settings, plus an application-specific suffix. Due to macOS restrictions the complete string must be 19 characters or shorter. For example:

    <pre class="language-xml" data-title="macos/Runner/*.entitlements"><code class="lang-xml">&#x3C;dict>
      &#x3C;key>com.apple.security.application-groups&#x3C;/key>
      &#x3C;array>
    <strong>    &#x3C;string>FGDTDLOBXDJ.demo&#x3C;/string>
    </strong>  &#x3C;/array>  
    ...  
    &#x3C;/dict>
    </code></pre>
3. When [initialising FMTC](../usage/initialisation.md), make sure to pass this string to the `macosApplicationGroup` argument
{% endtab %}

{% tab title="Web (unsupported)" %}
{% hint style="warning" %}
Although **FMTC will compile on the web**, the default FMTC [backend](../usage/initialisation.md#backends) does not support the web platform. `FMTCObjectBoxBackend.initialise` and `.uninitialise` will throw `UnsupportedError`s if invoked on the web. Other methods will throw `RootUnavailable` as normal.
{% endhint %}
{% endtab %}
{% endtabs %}

## Import

After installing the package, import it into the necessary files in your project:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```
