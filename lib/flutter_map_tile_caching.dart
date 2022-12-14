// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

library flutter_map_tile_caching;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bezier/bezier.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:queue/queue.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

import 'src/bulk_download/download_progress.dart';
import 'src/bulk_download/downloader.dart';
import 'src/bulk_download/internal_timing_progress_management.dart';
import 'src/bulk_download/tile_loops.dart';
import 'src/bulk_download/tile_progress.dart';
import 'src/db/defs/metadata.dart';
import 'src/db/defs/recovery.dart';
import 'src/db/defs/store.dart';
import 'src/db/defs/tile.dart';
import 'src/db/registry.dart';
import 'src/db/tools.dart';
import 'src/misc/enums.dart';
import 'src/misc/exts.dart';
import 'src/providers/tile_provider.dart';
import 'src/settings/fmtc_settings.dart';
import 'src/settings/tile_provider_settings.dart';

export 'package:flutter_background/flutter_background.dart'
    show AndroidResource;
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidNotificationDetails;

export 'src/bulk_download/download_progress.dart';
export 'src/misc/background_download_widget.dart';
export 'src/misc/enums.dart';
export 'src/settings/fmtc_settings.dart';
export 'src/settings/tile_provider_settings.dart';

part 'src/fmtc.dart';
part 'src/regions/base_region.dart';
part 'src/regions/circle.dart';
part 'src/regions/downloadable_region.dart';
part 'src/regions/line.dart';
part 'src/regions/recovered_region.dart';
part 'src/regions/rectangle.dart';
part 'src/root/directory.dart';
part 'src/root/import.dart';
part 'src/root/manage.dart';
part 'src/root/migrator.dart';
part 'src/root/recovery.dart';
part 'src/root/statistics.dart';
part 'src/store/directory.dart';
part 'src/store/download.dart';
part 'src/store/export.dart';
part 'src/store/manage.dart';
part 'src/store/metadata.dart';
part 'src/store/statistics.dart';
