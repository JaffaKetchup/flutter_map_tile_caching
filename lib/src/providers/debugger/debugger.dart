// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

typedef TileLoadingDebugMap = Map<TileCoordinates, TileLoadingDebugInfo>;

class TileLoadingDebugInfo {
  TileLoadingDebugInfo._();

  /// Indicates whether the tile completed loading successfully
  ///
  /// * `true`:  completed
  /// * `false`: errored
  late final bool didComplete;
}
