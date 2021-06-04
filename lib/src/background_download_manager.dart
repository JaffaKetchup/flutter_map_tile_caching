/*import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_map/flutter_map.dart';

import '../flutter_map_tile_caching.dart';



class BackgroundDownload {
  Future<void> _mainBackground(String originalTaskArgs) async {
    if (originalTaskArgs == 'flutter_background_fetch') {
      print(
          "The background task has been setup. Please standby for custom tasks.");
      //! Must finish background task
      print("The background task has finished successfully!");
      BackgroundFetch.finish(originalTaskArgs);
    } else {
      print("The background task was called. It's arguments are below...");

      final Map taskArgs = jsonDecode(originalTaskArgs);
      print(taskArgs);

      //! Must finish background task
      print("The background task has finished successfully!");
      BackgroundFetch.finish(originalTaskArgs);
    }
  }

  Future<void> startBackground(DownloadInfo info) async {
    //StorageCachingTileProvider().loadTiles(),
    int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(minimumFetchInterval: 15),
      _mainBackground,
      (String originalTaskArgs) async {
        // <-- Event timeout callback
        // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
        print("[BackgroundFetch] TIMEOUT taskId: $originalTaskArgs");
        BackgroundFetch.finish(originalTaskArgs);
      },
    );

    BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: jsonEncode(
          {
            "bounds": {
              "north": info.bounds.north,
              "east": info.bounds.east,
              "south": info.bounds.south,
              "west": info.bounds.west,
              "northeast": info.bounds.northEast,
              "northwest": info.bounds.northWest,
              "southeast": info.bounds.southEast,
              "southest": info.bounds.southWest,
            },
            "minZoom": info.minZoom,
            "maxZoom": info.maxZoom,
            "options": jsonEncode(info.options.)
          },
        ),
        delay: 5000,
        requiresStorageNotLow: true,
      ),
    );
  }
}
*/
import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart' show LatLngBounds;
import 'package:workmanager/workmanager.dart';

class DownloadInfo {
  LatLngBounds bounds;
  int minZoom;
  int maxZoom;
  String urlTemplate;
  List<String> subdomains;

  DownloadInfo(
      {required this.bounds,
      required this.minZoom,
      required this.maxZoom,
      required this.urlTemplate,
      required this.subdomains});
}

void _mainDownloader() {
  Workmanager().executeTask(
    (task, inputData) {
      print("Native called background task: $task");
      final DownloadInfo info = DownloadInfo(
        bounds: LatLngBounds(
          LatLng(
            jsonDecode(inputData!["bounds"])["north"],
            jsonDecode(inputData["bounds"])["west"],
          ),
          LatLng(
            jsonDecode(inputData["bounds"])["south"],
            jsonDecode(inputData["bounds"])["east"],
          ),
        ),
        minZoom: inputData["minZoom"],
        maxZoom: inputData["maxZoom"],
        urlTemplate: inputData["urlTemplate"],
        subdomains: inputData["subdomains"],
      );
      print(info);
      return Future.value(true);
    },
  );
}

class BackgroundMapDownload {
  static startDownload(DownloadInfo info) {
    Workmanager().initialize(
      _mainDownloader,
      isInDebugMode: true,
    );
    Workmanager().registerOneOffTask(
      "1",
      "downloadMap",
      inputData: {
        "bounds": jsonEncode({
          "north": info.bounds.north,
          "east": info.bounds.east,
          "south": info.bounds.south,
          "west": info.bounds.west,
        }),
        "minZoom": info.minZoom,
        "maxZoom": info.maxZoom,
        /*"options": jsonEncode({
          {
            "urlTemplate": info.options.urlTemplate,
            "tileSize": info.options.tileSize,
            "minZoom": info.options.minZoom,
            "maxZoom": info.options.maxZoom,
            "minNativeZoom": info.options.minNativeZoom,
            "maxNativeZoom": info.options.maxNativeZoom,
            "zoomReverse": info.options.zoomReverse,
            "zoomOffset": info.options.zoomOffset,
            "additionalOptions": jsonEncode(info.options.additionalOptions),
            "subdomains": info.options.subdomains,
            "keepBuffer": info.options.keepBuffer,
            "backgroundColor": info.options.backgroundColor,
            "placeholderImage": info.options.placeholderImage,
            "errorImage": info.options.errorImage,
            "tileProvider": info.options.tileProvider,
            "tms": info.options.tms,
            "wmsOptions": info.options.wmsOptions,
            "opacity": info.options.opacity,
            "updateInterval": info.options.updateInterval,
            "tileFadeInDuration": info.options.tileFadeInDuration,
            "tileFadeInStart": info.options.tileFadeInStart,
            "tileFadeInStartWhenOverride":
                info.options.tileFadeInStartWhenOverride,
            "overrideTilesWhenUrlChanges":
                info.options.overrideTilesWhenUrlChanges,
            "retinaMode": info.options.retinaMode,
            "errorTileCallback": info.options.errorTileCallback,
            "rebuild": info.options.rebuild,
            "templateFunction": info.options.templateFunction,
            "tileBuilder": info.options.tileBuilder,
            "tilesContainerBuilder": info.options.tilesContainerBuilder,
            "evictErrorTileStrategy": info.options.evictErrorTileStrategy,
            "fastReplace": info.options.fastReplace
          }
        }),*/
        "urlTemplate": info.urlTemplate,
        "subdomains": info.subdomains,
      },
    );
  }
}
