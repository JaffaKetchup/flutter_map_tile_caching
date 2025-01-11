// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Callback type for [FMTCTileProvider.urlTransformer] &
/// [StoreDownload.startForeground]
typedef UrlTransformer = String Function(String);

/// Callback type for [FMTCTileProvider.errorHandler]
typedef BrowsingExceptionHandler = Uint8List? Function(
  FMTCBrowsingError exception,
);
