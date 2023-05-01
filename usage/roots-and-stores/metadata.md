---
description: Applies only to Stores
---

# Metadata

```dart
FlutterMapTileCaching.instance('storeName').metadata;
```

This library provides a very simple persistent key-value pair storage system, designed to store any custom information about the store. These are stored alongside tiles in the tile database.

For example, your application may use one store per `urlTemplate`, in which case, the URL can be stored in the metadata.

{% hint style="info" %}
Remember that `metadata` does not have any effect on internal logic: it is simply an auxiliary method of storing any data that might need to be kept alongside a store.
{% endhint %}

{% hint style="success" %}
Both asynchronous and synchronous versions of the below methods are available.
{% endhint %}

## Add

Add a new key-value pair to the store. For example:

```dart
    add(
        key: String,
        value: String,
    );
```

## Read

Read all the key-value pairs from the store, and return them in a `Map<String, String>`. For example:

```dart
    read; // This is a getter
```

## Remove

Remove a key-value pair from the store. For example:

```dart
    remove(key: String);
```

## Reset

Remove all the key-value pairs from the store. For example:

```dart
    reset();
```
