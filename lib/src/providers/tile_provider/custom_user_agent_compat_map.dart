// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Custom override of [Map] that only overrides the [MapView.putIfAbsent]
/// method, to enable injection of an identifying mark ("FMTC")
class _CustomUserAgentCompatMap extends MapView<String, String> {
  const _CustomUserAgentCompatMap(super.map);

  /// Modified implementation of [MapView.putIfAbsent], that overrides behaviour
  /// only when [key] is "User-Agent"
  ///
  /// flutter_map's [TileLayer] constructor calls this method after the
  /// [TileLayer.tileProvider] has been constructed to customize the
  /// "User-Agent" header with `TileLayer.userAgentPackageName`.
  /// This method intercepts any call with [key] equal to "User-Agent" and
  /// replacement value that matches the expected format, and adds an "FMTC"
  /// identifying mark.
  ///
  /// The identifying mark is injected to seperate traffic sent via FMTC from
  /// standard flutter_map traffic, as it significantly changes the behaviour of
  /// tile retrieval, and could generate more traffic.
  @override
  String putIfAbsent(String key, String Function() ifAbsent) {
    if (key != 'User-Agent') return super.putIfAbsent(key, ifAbsent);

    final replacementValue = ifAbsent();
    if (!RegExp(r'flutter_map \(.+\)').hasMatch(replacementValue)) {
      return super.putIfAbsent(key, ifAbsent);
    }
    return this[key] = replacementValue.replaceRange(11, 12, ' + FMTC ');
  }
}
