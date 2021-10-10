// This is `flutter_map_tile_caching's` main file
// You should never need to include anything other than this file from this library in your project

// Main
export 'src/main.dart';
export 'src/storageManager.dart';
export 'src/misc.dart' hide ListExtensionsE, ListExtensionsDouble;
export 'src/bulkDownload/downloadProgress.dart';

// Regions
export 'src/regions/downloadableRegion.dart';
export 'src/regions/recoveredRegion.dart';
export 'src/regions/rectangle.dart';
export 'src/regions/circle.dart';
export 'src/regions/line.dart';

// Other Libraries
export 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult;
export 'package:battery_info/enums/charging_status.dart';

// Deprecated
export 'src/deprecated/oldCachingManager.dart';
export 'src/deprecated/shapeChooser.dart';
