// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

/// Specialised sub-library of FMTC which provides access to some semi-public
/// internals necessary to create custom backends or work more directly with
/// them
///
/// Use this import/library with caution! Assistance with non-typical usecases
/// may be limited. Always use the standard import unless necessary.
///
/// Importing the standard library will also likely be necessary.
library flutter_map_tile_caching.custom_backend_api;

export 'src/backend/export_internal.dart';
