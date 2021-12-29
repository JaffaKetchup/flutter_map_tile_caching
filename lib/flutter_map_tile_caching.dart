// This is 'flutter_map_tile_caching's' main file
// You should never need to include anything other than this file from this library in your project

export 'src/main.dart';

// Misc
export 'src/misc/typedefs.dart';
export 'src/misc/validate.dart' hide safeFilesystemString;

// Storage Managers & Download Progress
export 'src/storageManagers/storage_manager.dart';
export 'src/storageManagers/async_storage_manager.dart';
export 'src/bulkDownload/download_progress.dart';

// Regions
export 'src/regions/downloadable_region.dart';
export 'src/regions/recovered_region.dart';
export 'src/regions/rectangle.dart';
export 'src/regions/circle.dart';
export 'src/regions/line.dart';

// Other Libraries
export 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult;
export 'package:battery_info/enums/charging_status.dart';

// Deprecated
export 'src/deprecated/old_caching_manager.dart';
export 'src/deprecated/shape_chooser.dart';
