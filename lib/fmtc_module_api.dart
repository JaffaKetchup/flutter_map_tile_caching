// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: invalid_export_of_internal_element

/// Restricted API which exports internal functionality, necessary for the FMTC
/// modules to work correctly
///
/// **Do not use in normal applications. Prefer importing
/// 'flutter_map_tile_caching.dart'.**
library fmtc_module_api;

export 'src/db/defs/metadata.dart';
export 'src/db/defs/store_descriptor.dart';
export 'src/db/defs/tile.dart';
export 'src/db/registry.dart';
export 'src/db/tools.dart';
export 'src/misc/exts.dart';
