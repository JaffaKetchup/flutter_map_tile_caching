// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

class _AllowedNotifyValueNotifier<T> extends ValueNotifier<T> {
  _AllowedNotifyValueNotifier(super._value);

  // Removes the `@protected` annotation, as we want to perform this operation
  // ourselves
  @override
  void notifyListeners() => super.notifyListeners();
}
