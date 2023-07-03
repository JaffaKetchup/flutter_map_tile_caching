// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

@internal
class DownloadInstance {
  DownloadInstance._(this.id);
  static final Map<Object, DownloadInstance> _instances = {};

  static DownloadInstance? registerIfAvailable(Object id) =>
      _instances.containsKey(id)
          ? null
          : _instances[id] ??= DownloadInstance._(id);
  static bool unregister(Object id) => _instances.remove(id) != null;
  static DownloadInstance? get(Object id) => _instances[id];

  final Object id;
  Future<void> Function()? cancelDownloadRequest;
}
