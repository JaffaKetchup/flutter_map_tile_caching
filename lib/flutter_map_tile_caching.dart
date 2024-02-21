// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

/// A plugin for flutter_map providing advanced caching functionality, with
/// ability to download map regions for offline use. Also includes useful
/// prebuilt widgets.
///
/// * [GitHub Repository](https://github.com/JaffaKetchup/flutter_map_tile_caching)
/// * [pub.dev Package](https://pub.dev/packages/flutter_map_tile_caching)
///
/// * [Documentation Site](https://fmtc.jaffaketchup.dev/)
/// * [Full API Reference](https://pub.dev/documentation/flutter_map_tile_caching/latest/flutter_map_tile_caching/flutter_map_tile_caching-library.html)
library flutter_map_tile_caching;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'src/backend/export_internal.dart';
import 'src/bulk_download/instance.dart';
import 'src/bulk_download/rate_limited_stream.dart';
import 'src/bulk_download/tile_loops/shared.dart';
import 'src/errors/browsing.dart';
import 'src/misc/int_extremes.dart';
import 'src/misc/obscure_query_params.dart';
import 'src/providers/image_provider.dart';

export 'src/backend/export_external.dart';
export 'src/errors/browsing.dart';
export 'src/errors/damaged_store.dart';

part 'src/bulk_download/download_progress.dart';
part 'src/bulk_download/manager.dart';
part 'src/bulk_download/thread.dart';
part 'src/bulk_download/tile_event.dart';
part 'src/misc/deprecations.dart';
part 'src/providers/tile_provider.dart';
part 'src/regions/base_region.dart';
part 'src/regions/circle.dart';
part 'src/regions/custom_polygon.dart';
part 'src/regions/downloadable_region.dart';
part 'src/regions/line.dart';
part 'src/regions/recovered_region.dart';
part 'src/regions/rectangle.dart';
part 'src/root/directory.dart';
part 'src/root/import.dart';
part 'src/root/recovery.dart';
part 'src/root/statistics.dart';
part 'src/providers/tile_provider_settings.dart';
part 'src/store/directory.dart';
part 'src/store/download.dart';
part 'src/store/export.dart';
part 'src/store/manage.dart';
part 'src/store/metadata.dart';
part 'src/store/statistics.dart';
