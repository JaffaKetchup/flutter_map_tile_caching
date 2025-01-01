// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

enum _DownloadManagerControlCmd {
  cancel,
  resume,
  pause,
  startEmittingDownloadProgress,
  stopEmittingDownloadProgress,
  startEmittingTileEvents,
  stopEmittingTileEvents,
}
