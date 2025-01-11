# Initialisation

{% hint style="warning" %}
**FMTC is licensed under GPL-v3.**

If you're developing an application that isn't licensed under GPL, this affects you and your application's legal right to distribution. For more information, please see [proprietary-licensing.md](../proprietary-licensing.md "mention").
{% endhint %}

FMTC relies on a self-contained 'environment', called a [#backends](initialisation.md#backends "mention"), that requires initialisation (and configuration) before it can be used. This allows the backend to start any necessary seperate threads/isolates, load any prerequisites, and open and maintain a connection to a database. This environment/backend is then accessible internally through a(\*[^1]) singleton, so initialisation is not required again.

## Initialisation

Initialisation should be performed before any other FMTC or backend methods are used, and so it is usually placed just before `runApp`, in the `main` method. This shouldn't have any significant effect on application startup time.

{% hint style="warning" %}
If initialising in the `main` method before `runApp` is called, ensure you also call `WidgetsFlutterBinding.ensureInitialised()` prior to the backend initialisation.
{% endhint %}

<pre class="language-dart" data-title="main.dart"><code class="lang-dart">import 'package:flutter/widgets.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Future&#x3C;void> main() async {
    WidgetsFlutterBinding.ensureInitialized();   
    
    try {
<strong>        await FMTCObjectBoxBackend().initialise(...); // The default/built-in backend
</strong>    } catch (error, stackTrace) {
        // See below for error/exception handling
    }
    
    // ...
    
    runApp(MyApp());
}
</code></pre>

{% hint style="danger" %}
Do not call any other FMTC methods before initialisation. Doing so will cause a `RootUnavailable` error to be thrown.
{% endhint %}

{% hint style="danger" %}
Do not attempt to initialise the same backend multiple times, or initialise multiple backends simultaenously. Doing so will cause a `RootAlreadyInitialised` error to be thrown.
{% endhint %}

{% hint style="warning" %}
Avoid using FMTC in a seperate thread/`Isolate`. FMTC backends already make extensive use of multi-threading to improve performance.

If it is essential to use FMTC in a seperate thread, ensure that the initialisation is called in the thread where it is used. Be cautious of using FMTC manually across multiple threads simultaneously, as backends may not properly support this, and unexpected behaviours may occur.
{% endhint %}

### Error Handling

One particular place where exceptions can occur more frequently is during initialisation. The code sample above includes a `try`/`catch` block to catch these errors. If an exception occurs at this point, it's likely unrecoverable (for example, it might indicate that the underlying database has been corrupted), and the best course of action is often to manually delete the FMTC root directory from the filesystem.

The default directory can be found and deleted with the following snippet (which requires 'package:path' and 'package:path\_provider':

```dart
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final dir = Directory(
  path.join(
    (await getApplicationDocumentsDirectory()).absolute.path,
    'fmtc',
  ),
);

await dir.delete(recursive: true);

// Then reinitialise FMTC
```

## Uninitialisation

It is also possible to un-initialise FMTC and the current backend. This should be rarely required, but can be performed through the `uninitialise` method of the backend if required. Initialisation is possible after manual uninitialisation.

## Backends

FMTC supports attachment of any custom storage mechanism, through an `FMTCBackend`. This allows users to pick their favourite database engine, or conduct in-memory testing.

{% hint style="success" %}
Only one backend is built-into FMTC: the `FMTCObjectBoxBackend`. This backend uses the [ObjectBox library](https://pub.dev/packages/objectbox) to store data.
{% endhint %}

{% hint style="warning" %}
ObjectBox has a complex license model - the build time dependency is open-source, whilst the native library _runtime only_ dependency is under a closed-source (but relatively relaxed) [license](https://objectbox.io/0209-ob-binary-license/) (that is liable to change at ObjectBox's will).

This is not an issue for the majority of applications. However, ObjectBox is known to be (rightly or wrongly) banned as a dependency from apps on F-Droid (last checked September 2024).

Future updates to FMTC will implement alternative backends using other libraries, and the default/preferred backend may indeed change in future.

For more information, please see: [https://github.com/JaffaKetchup/flutter\_map\_tile\_caching/issues/167](https://github.com/JaffaKetchup/flutter_map_tile_caching/issues/167).
{% endhint %}

[^1]: Internally, more than one singleton may be used in a backend, and to access a backend. However, this is beyond the scope of this page.
