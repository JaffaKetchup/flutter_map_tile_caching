// This is flutter_map_tile_caching's main file
// You should never need to include anything other than this file from this library in your project

// Main
export 'src/main.dart';
//export 'src/tileLayer.dart'; EXPERIMENTAL

// Backend and Misc
export 'src/storageManager.dart';
export 'src/misc.dart' hide ListExtensionsE, ListExtensionsDouble;

// Regions
export 'src/regions/downloadableRegion.dart';
export 'src/regions/recoveredRegion.dart';
export 'src/regions/rectangle.dart';
export 'src/regions/circle.dart';
export 'src/regions/line.dart';

// Widgets
//export 'src/widgets/cacheScreen.dart'; EXPERIMENTAL
//export 'src/widgets/sourceSwitcher.dart'; EXPERIMENTAL

// Deprecated
export 'src/deprecated/oldCachingManager.dart';
export 'src/deprecated/shapeChooser.dart';
