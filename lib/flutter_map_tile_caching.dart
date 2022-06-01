/// Main import point for 'flutter_map_tile_caching'
///
/// Checkout the README for more documentation.
///
/// Exports all objects that you should need in normal use, including from dependencies.
///
/// If you require access to full API, import `package:flutter_map_tile_caching/fmtc_advanced.dart` instead.
library flutter_map_tile_caching;

import 'src/internal/store/directory.dart' as store_directory_import;

export 'dart:io' show Directory, File, FileSystemEvent;

export 'package:battery_info/enums/charging_status.dart';
export 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult;

export 'src/bulk_download/download_progress.dart';
export 'src/fmtc.dart';
export 'src/misc/cache_behavior.dart';
export 'src/misc/typedefs.dart';
export 'src/misc/validate.dart';
export 'src/regions/circle.dart';
export 'src/regions/downloadable_region.dart';
export 'src/regions/line.dart';
export 'src/regions/recovered_region.dart';
export 'src/regions/rectangle.dart';
export 'src/root/directory.dart';
export 'src/settings/tile_provider_settings.dart';

typedef StoreDirectory = store_directory_import.StoreDirectory;
