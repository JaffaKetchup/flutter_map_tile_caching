# Installation

{% hint style="warning" %}
**FMTC is licensed under GPL-v3.**

If you're developing an application that isn't licensed under GPL, this affects you and your application's legal right to distribution. For more information, please see [proprietary-licensing.md](../proprietary-licensing.md "mention").
{% endhint %}

{% hint style="success" %}
Looking to start using FMTC in your project? Check out the [quickstart.md](quickstart.md "mention") guide!
{% endhint %}

## Depend On

### From [pub.dev](https://pub.dev/packages/flutter_map_tile_caching)

This is the recommended method of installing this package as it ensures you only receive the latest stable versions, and you can be sure pub.dev is reliable.

Just import the package as you would normally, from the command line:

```shell
flutter pub add flutter_map_tile_caching
```

### From [github.com](https://github.com/JaffaKetchup/flutter_map_tile_caching)

If you urgently need the latest version, a specific branch, or a specific fork, you can use this method.

{% hint style="info" %}
Commits available from Git (GitHub) may not be stable. Only use this method if you have no other choice.
{% endhint %}

First, add the normal dependency following the [#from-pub.dev](installation.md#from-pub.dev "mention") instructions. Then, add the following lines to your pubspec.yaml file under the `dependencies_override` section:

{% code title="pubspec.yaml" %}
```yaml
dependency_overrides:
    flutter_map_tile_caching:
        git:
            url: https://github.com/JaffaKetchup/flutter_map_tile_caching.git
            # ref: a commit hash, branch name, or tag (otherwise defaults to master)
```
{% endcode %}

## Import

After installing the package, import it into the necessary files in your project:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
// You'll also need to import flutter_map and (likely) latlong2 seperately
```

{% hint style="success" %}
You may need to follow ObjectBox's installation instructions for your platform:  [https://docs.objectbox.io/getting-started](https://docs.objectbox.io/getting-started).

If building for Android, and Gradle errors on build due to the 'ndkVersion' being too low, edit your Gradle config as shown in the error message.
{% endhint %}

{% hint style="warning" %}
Although FMTC will compile on the web, the default `FMTCObjectBoxBackend` (see [#backends](../usage/initialisation.md#backends "mention")) does not support the web platform: the `initialise` and `uninitialise` methods (see [initialisation.md](../usage/initialisation.md "mention")) will throw `UnsupportedError`s, and other methods will throw `RootUnavailable`.
{% endhint %}
