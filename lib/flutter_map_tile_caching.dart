/// Main import point for 'flutter_map_tile_caching'
///
/// Checkout the README for more documentation.
///
/// Exports all objects that you should need in normal use, including from dependencies.
///
/// If you require access to full API, import `package:flutter_map_tile_caching/fmtc_advanced.dart` instead.
library flutter_map_tile_caching;

export 'src/fmtc.dart';
export 'src/main.dart';

export 'src/misc/typedefs.dart';
export 'src/misc/validate.dart' hide safeFilesystemString;
export 'src/misc/cache_behavior.dart';

export 'src/root/directory.dart';

export 'src/bulk_download/download_progress.dart';

export 'src/regions/downloadable_region.dart';
export 'src/regions/recovered_region.dart';
export 'src/regions/rectangle.dart';
export 'src/regions/circle.dart';
export 'src/regions/line.dart';

export 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult;
export 'package:battery_info/enums/charging_status.dart';
export 'dart:io' show Directory, File, FileSystemEvent;
