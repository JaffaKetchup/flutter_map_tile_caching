// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

/// Main import point for 'flutter_map_tile_caching'
///
/// Checkout the README for more documentation.
///
/// Exports all objects that you should need in normal use, including from dependencies.
///
/// If you require access to full API, import `package:flutter_map_tile_caching/fmtc_advanced.dart` instead.
library flutter_map_tile_caching;

export 'dart:io' show Directory, File;

export 'package:flutter_background/flutter_background.dart'
    show AndroidResource;
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidNotificationDetails;
export 'package:watcher/watcher.dart' show ChangeType;

export 'src/bulk_download/download_progress.dart';
export 'src/fmtc.dart';
export 'src/misc/background_download_widget.dart';
export 'src/misc/enums.dart';
export 'src/regions/base_region.dart';
export 'src/regions/circle.dart';
export 'src/regions/downloadable_region.dart';
export 'src/regions/line.dart';
export 'src/regions/recovered_region.dart';
export 'src/regions/rectangle.dart';
export 'src/root/directory.dart';
export 'src/settings/filesystem_sanitiser_public.dart';
export 'src/settings/fmtc_settings.dart';
export 'src/settings/tile_provider_settings.dart';
export 'src/store/directory.dart';
