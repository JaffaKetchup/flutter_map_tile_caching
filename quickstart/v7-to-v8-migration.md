# v7 -> v8 Migration

{% hint style="success" %}
v8 brings major performance & stability improvements, along with support for Isar v3.1 and 'flutter\_map' v4.
{% endhint %}

Some migrations are necessary for a **small number of users**. These migrations are listed below, theoretically in decreasing number of affected users.

The underlying storage structure is directly compatible with v7, and so migration for that is not required.

## Importing

{% hint style="info" %}
The [`fmtc_plus_sharing`](https://github.com/JaffaKetchup/fmtc\_plus\_sharing) module is required to use the import/export functionality.

See the [#fmtc\_plus\_sharing-installation-and-setup](../get-started/additional-setup.md#fmtc\_plus\_sharing-installation-and-setup "mention") instructions to add this module.
{% endhint %}

* **Return type is now `ImportResult`**\
  This contains both the real store name (may be different to the filename) and whether the import was successful.
* **Collision handlers are now called with an additional argument**\
  The filename and real store name are now both passed to the collision handler. See [#collision-conflict-resolution](../import-and-export/importing.md#collision-conflict-resolution "mention").

## Initialisation

`FMTCInitialisationException`'s fields have changed to be more useful in debugging initialisation issues, both internally and externally. If _processing_ these issues manually, you'll need to migrate. See the in-code documentation for more information.

## Custom `HttpClient` Usage

FMTC now supports HTTP/2, through ['http\_plus'](https://pub.dev/packages/http\_plus)! HTTP/2 support is enabled by default, with a fallback to HTTP/1.1 (both with a timeout of 5 seconds).&#x20;

In many of the places where `HttpClient`s where previously accepted as arguments, `BaseClient` subtypes are now required. To continue using a custom `HttpClient`, wrap it with an `IOClient`.
