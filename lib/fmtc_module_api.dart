// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: invalid_export_of_internal_element

/// Restricted API which exports internal functionality, necessary for the FMTC
/// modules to work correctly
///
/// When importing this library, also import 'flutter_map_tile_caching.dart' for
/// the full functionality set.
///
/// ---
///
/// "With great power comes great responsibility" - Someone
///
/// This library forms part of a layer of abstraction between you, FMTC
/// internals, and underlying databases. Importing this library removes that
/// abstraction, making it easy to disrupt FMTC's normal operations with
/// incorrect usage. For example, it is possible to force close an open Isar
/// database, leading to an erroneous & invalid state.
///
/// If you are using this to create a custom module, go ahead! Please do get in
/// touch, I'm always interested to hear what the community is making, and I may
/// be able to offer some insight into the darker corners and workings of FMTC.
/// Note that not necessarily all internal APIs are exposed through this library.
///
/// **Do not use in normal applications. I may be unable to offer support.**
library fmtc_module_api;

export 'src/db/defs/metadata.dart';
export 'src/db/defs/store_descriptor.dart';
export 'src/db/defs/tile.dart';
export 'src/db/registry.dart';
export 'src/db/tools.dart';
export 'src/misc/exts.dart';
