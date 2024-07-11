// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

@internal
class DownloadInstance {
  DownloadInstance._(this.id);
  static final _instances = <Object, DownloadInstance>{};

  static DownloadInstance? registerIfAvailable(Object id) =>
      _instances[id] != null ? null : _instances[id] = DownloadInstance._(id);
  static bool unregister(Object id) => _instances.remove(id) != null;
  static DownloadInstance? get(Object id) => _instances[id];

  final Object id;

  bool isPaused = false;

  // The following callbacks are defined by the `StoreDownload.startForeground`
  // method, when a download is started, and are tied to that download operation
  Future<void> Function()? requestCancel;
  Future<void> Function()? requestPause;
  void Function()? requestResume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DownloadInstance && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
