//! TODO: Add 'flutter_map', 'flutter_map_tile_caching', 'sliding_up_panel', 'connectivity_plus' to pubspec.yaml

import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() {
  runApp(DemoApp());
}

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_map_tile_caching Demo',
      home: MapScreen(),
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController mapController;
  late final PanelController panelController;
  late final TextEditingController newStoreInputController;
  late TextEditingController renameStoreInputController;
  late TextEditingController maxZoomInputController;
  late TextEditingController minZoomInputController;

  final Duration animationDuration = Duration(milliseconds: 250);
  final Duration animationDurationSlow = Duration(milliseconds: 500);
  final Curve animationCurve = Curves.easeInOut;

  bool forceUseCellular = false;

  bool lockRotation = true;

  String? storeName;
  bool renaming = false;
  double panelUIOpacity = 0;

  RegionType? selectingDownloadRegion;
  List<LatLng> prevTappedLocations = [];
  List<LatLng> tappedLocations = [];

  bool lockPreventRedownload = false;
  bool enablePreventRedownload = false;
  bool enableSeaTileRemoval = true;
  bool enableTileCompression = false;
  int prevMinZoom = -1;
  int prevMaxZoom = -1;
  int prevEstTiles = -1;
  int minZoom = 1;
  int maxZoom = 18;

  bool downloadInProgress = false;
  bool downloadJustFinished = false;
  bool downloadingInBackground = false;
  bool cancelBackgroundFlag = false;
  double percentageComplete = 0;
  String durationElapsed = '';
  String estRemainingDuration = '';
  String successfulTiles = '0';
  String failedTiles = '0';
  StorageCachingTileProvider? downloadProvider;

  void newStoreNameSubmitted(
    String _storeName,
    CacheDirectory parentDirectory,
  ) {
    if (renaming)
      MapCachingManager(parentDirectory, storeName!).renameStore(_storeName);

    setState(() {
      storeName = _storeName.trim();
      renameStoreInputController = TextEditingController(text: storeName!);
      renaming = false;
    });

    final RecoveredRegion? recovered = StorageCachingTileProvider(
            parentDirectory: parentDirectory, storeName: storeName!)
        .recoverDownload();
    if (recovered == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found an incomplete download'),
        action: SnackBarAction(
            label: 'Recover It',
            onPressed: () {
              if (recovered.type == RegionType.rectangle) {
                setState(() {
                  tappedLocations = [
                    recovered.bounds!.northWest,
                    recovered.bounds!.southEast,
                  ];
                  selectingDownloadRegion = RegionType.rectangle;
                });
              } else {
                setState(() {
                  tappedLocations = [
                    recovered.center!,
                    Distance().offset(recovered.center!, recovered.radius!, 0),
                  ];
                  selectingDownloadRegion = RegionType.circle;
                });
              }
              setState(() {
                minZoomInputController.text = recovered.minZoom.toString();
                maxZoomInputController.text = recovered.maxZoom.toString();
                enablePreventRedownload = recovered.preventRedownload;
                enableSeaTileRemoval = recovered.seaTileRemoval;
                enableTileCompression = recovered.compressionQuality != -1;
                lockPreventRedownload = true;
                downloadInProgress = false;
              });
            }),
        duration: Duration(seconds: 10),
      ),
    );
  }

  void startDownload(CacheDirectory parentDirectory, DownloadableRegion region,
      {bool background = false, bool noRecovery = false}) {
    setState(() {
      downloadInProgress = true;
      selectingDownloadRegion = null;
      downloadProvider = StorageCachingTileProvider(
        parentDirectory: parentDirectory,
        storeName: storeName!,
      );
    });
    if (background) {
      setState(() {
        downloadingInBackground = true;
      });
      try {
        downloadProvider!.downloadRegionBackground(
          region,
          callback: (DownloadProgress progress) {
            setState(() {
              percentageComplete = progress.percentageProgress;
              durationElapsed = progress.duration.toString().split('.')[0];
              estRemainingDuration =
                  progress.estRemainingDuration.toString().split('.')[0];
              successfulTiles = progress.successfulTiles.toString();
              failedTiles = progress.failedTiles.length.toString();
              if (progress.percentageProgress == 100) {
                downloadJustFinished = true;
                downloadingInBackground = false;
              }
            });
            if (cancelBackgroundFlag) {
              setState(() {
                cancelBackgroundFlag = false;
                downloadingInBackground = false;
              });
              return true;
            }
            return false;
          },
          useAltMethod: true,
        );
      } catch (e) {
        if (e is StateError) {
          setState(() {
            downloadInProgress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('An error occurred:\nFailed to create recovery session'),
            ),
          );
        }
        rethrow;
      }
    } else {
      late final Stream<DownloadProgress> downloadStream;
      try {
        downloadStream = downloadProvider!.downloadRegion(
          region,
          disableRecovery: noRecovery,
        );
      } catch (e) {
        if (e is StateError) {
          setState(() {
            downloadInProgress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('An error occurred:\nFailed to create recovery session'),
              action: SnackBarAction(
                label: 'Retry Without Recovery',
                onPressed: () {
                  startDownload(
                    parentDirectory,
                    region,
                    background: background,
                    noRecovery: true,
                  );
                },
              ),
            ),
          );
        }
        rethrow;
      }

      downloadStream.listen((progress) {
        setState(() {
          percentageComplete = progress.percentageProgress;
          durationElapsed = progress.duration.toString().split('.')[0];
          estRemainingDuration =
              progress.estRemainingDuration.toString().split('.')[0];
          successfulTiles = progress.successfulTiles.toString();
          failedTiles = progress.failedTiles.length.toString();
          if (progress.percentageProgress == 100) {
            downloadJustFinished = true;
          }
        });
      });
    }
  }

  @override
  void initState() {
    mapController = MapController();
    panelController = PanelController();
    newStoreInputController = TextEditingController();
    maxZoomInputController = TextEditingController()..text = '18';
    minZoomInputController = TextEditingController()..text = '1';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('flutter_map_tile_caching Demo'),
      ),
      body: FutureBuilder<CacheDirectory>(
        future: MapCachingManager.normalDirectory,
        builder: (context, dir) {
          if (dir.data == null)
            return Center(
              child: CircularProgressIndicator(),
            );
          final TileLayerOptions tileLayerOptions = TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            tileProvider: storeName == null
                ? NonCachingNetworkTileProvider()
                : StorageCachingTileProvider(
                    parentDirectory: dir.data!,
                    storeName: storeName!,
                  ),
          );
          return SlidingUpPanel(
            controller: panelController,
            onPanelSlide: (num) => setState(() {
              panelUIOpacity = num;
            }),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            backdropEnabled: true,
            panel: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(height: 8),
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width / 4,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                      SizedBox(
                        height: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Cache Manager',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Opacity(
                    opacity: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          height: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 35),
                              Visibility(
                                visible: storeName == null,
                                child: Opacity(
                                  opacity: 1 - panelUIOpacity,
                                  child: Text('No cache chosen'),
                                ),
                              ),
                              Visibility(
                                visible: storeName != null,
                                child: Text('Caching to: $storeName'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: panelUIOpacity,
                    child: Column(
                      children: [
                        SizedBox(height: 100),
                        Expanded(
                          child: storeName == null || renaming
                              ? Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      !renaming
                                          ? Icons.file_download_off
                                          : Icons.edit,
                                      size: 56,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      renaming
                                          ? 'Enter a new name for the store:'
                                          : 'You aren\'t caching anything yet\nGet started by choosing a name:',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding:
                                          EdgeInsets.only(left: 15, right: 15),
                                      child: TextField(
                                        controller: newStoreInputController,
                                        maxLengthEnforcement:
                                            MaxLengthEnforcement.none,
                                        maxLength: 40,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        decoration: InputDecoration(
                                          hintText: renaming ? null : 'London',
                                          helperText: renaming
                                              ? 'Enter the new name for the store \'$storeName\''
                                              : 'Enter the name of a new or existing store',
                                          suffixIcon: IconButton(
                                            onPressed: newStoreInputController
                                                        .text ==
                                                    ''
                                                ? null
                                                : () => newStoreNameSubmitted(
                                                      newStoreInputController
                                                          .text,
                                                      dir.data!,
                                                    ),
                                            icon: Icon(Icons.arrow_forward),
                                          ),
                                        ),
                                        onSubmitted: (String str) => str != ''
                                            ? newStoreNameSubmitted(
                                                str, dir.data!)
                                            : null,
                                        onChanged: (_) => setState(() {}),
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              (MapCachingManager(
                                                            dir.data!,
                                                            storeName!,
                                                          )
                                                              .storeSize
                                                              ?.bytesToMegabytes ??
                                                          0)
                                                      .toStringAsFixed(2) +
                                                  ' MB',
                                              style: TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Total Size',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              (MapCachingManager(
                                                        dir.data!,
                                                        storeName!,
                                                      ).storeLength ??
                                                      0)
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Total Tiles',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              ((((MapCachingManager(
                                                                            dir.data!,
                                                                            storeName!,
                                                                          ).storeSize ??
                                                                          0) /
                                                                      1024) /
                                                                  (MapCachingManager(
                                                                        dir.data!,
                                                                        storeName!,
                                                                      ).storeLength ??
                                                                      0))
                                                              .isNaN
                                                          ? 0
                                                          : (((MapCachingManager(
                                                                        dir.data!,
                                                                        storeName!,
                                                                      ).storeSize ??
                                                                      0) /
                                                                  1024) /
                                                              (MapCachingManager(
                                                                    dir.data!,
                                                                    storeName!,
                                                                  ).storeLength ??
                                                                  0)))
                                                      .toStringAsFixed(2) +
                                                  ' KB',
                                              style: TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Avg. Tile Size',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: downloadInProgress &&
                                                    !downloadJustFinished
                                                ? null
                                                : () {
                                                    setState(() {
                                                      renaming = true;
                                                    });
                                                  },
                                            child: Text('Rename'),
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: downloadInProgress &&
                                                    !downloadJustFinished
                                                ? null
                                                : () {
                                                    setState(() {
                                                      MapCachingManager(
                                                        dir.data!,
                                                        storeName!,
                                                      ).deleteStore();
                                                      storeName = null;
                                                    });
                                                  },
                                            child: Text('Delete'),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: downloadInProgress &&
                                                    !downloadJustFinished
                                                ? null
                                                : () {
                                                    setState(() {
                                                      storeName = null;
                                                    });
                                                  },
                                            child: Text('Disable'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 30),
                                    Visibility(
                                      visible:
                                          selectingDownloadRegion == null &&
                                              !downloadInProgress,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectingDownloadRegion =
                                                      RegionType.rectangle;
                                                });
                                              },
                                              child: Text(
                                                  'Download Rectangular Region'),
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectingDownloadRegion =
                                                      RegionType.circle;
                                                });
                                              },
                                              child: Text(
                                                  'Download Circular Region'),
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: null,
                                              child: Text(
                                                  'Download Line-Based Region'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible:
                                          selectingDownloadRegion != null &&
                                              tappedLocations.length != 2,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectingDownloadRegion =
                                                      null;
                                                  tappedLocations = [];
                                                });
                                              },
                                              child: Text('Cancel'),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.touch_app,
                                                size: 32,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  selectingDownloadRegion ==
                                                          RegionType.rectangle
                                                      ? 'To select a rectangular area to download, tap on the top-left and bottom-right of the area in that order. Alternatively, cancel the selection above.'
                                                      : 'To select a circular area to download, tap on the center of the circle, then on the edge of the circle. Alternatively, cancel the selection above.',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible:
                                          selectingDownloadRegion != null &&
                                              tappedLocations.length == 2,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Column(
                                                children: [
                                                  FutureBuilder<int>(
                                                    future: minZoom != prevMinZoom ||
                                                            maxZoom !=
                                                                prevMaxZoom ||
                                                            !ListEquality().equals(
                                                                tappedLocations,
                                                                prevTappedLocations)
                                                        ? (tappedLocations
                                                                    .length ==
                                                                2
                                                            ? StorageCachingTileProvider
                                                                .checkRegion(
                                                                selectingDownloadRegion ==
                                                                        RegionType
                                                                            .rectangle
                                                                    ? RectangleRegion(
                                                                        LatLngBounds(
                                                                            tappedLocations[0],
                                                                            tappedLocations[1]),
                                                                      ).toDownloadable(
                                                                        minZoom,
                                                                        maxZoom,
                                                                        tileLayerOptions,
                                                                      )
                                                                    : CircleRegion(
                                                                        tappedLocations[
                                                                            0],
                                                                        Distance().distance(tappedLocations[0],
                                                                                tappedLocations[1]) /
                                                                            1000,
                                                                      ).toDownloadable(
                                                                        minZoom,
                                                                        maxZoom,
                                                                        tileLayerOptions,
                                                                      ),
                                                              )
                                                            : Future.sync(
                                                                () => 0))
                                                        : Future.sync(
                                                            () => prevEstTiles),
                                                    builder:
                                                        (context, tilesLength) {
                                                      if (!tilesLength
                                                              .hasData ||
                                                          tilesLength
                                                                  .connectionState !=
                                                              ConnectionState
                                                                  .done) {
                                                        if (prevEstTiles ==
                                                                -1 ||
                                                            minZoom !=
                                                                prevMinZoom ||
                                                            maxZoom !=
                                                                prevMaxZoom ||
                                                            !ListEquality().equals(
                                                                tappedLocations,
                                                                prevTappedLocations))
                                                          return CircularProgressIndicator();
                                                        return Text(
                                                          prevEstTiles
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        );
                                                      }
                                                      prevMinZoom = minZoom;
                                                      prevMaxZoom = maxZoom;
                                                      prevEstTiles =
                                                          tilesLength.data!;
                                                      prevTappedLocations =
                                                          tappedLocations;
                                                      return Text(
                                                        tilesLength.data
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Text(
                                                    'Estimated Tiles',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        height: 20,
                                                        child: Switch(
                                                          value:
                                                              enablePreventRedownload,
                                                          onChanged: lockPreventRedownload
                                                              ? null
                                                              : (bool newVal) =>
                                                                  setState(() =>
                                                                      enablePreventRedownload =
                                                                          newVal),
                                                        ),
                                                      ),
                                                      Text('Prevent Redownload')
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        height: 20,
                                                        child: Switch(
                                                          value:
                                                              enableSeaTileRemoval,
                                                          onChanged: (bool
                                                                  newVal) =>
                                                              setState(() =>
                                                                  enableSeaTileRemoval =
                                                                      newVal),
                                                        ),
                                                      ),
                                                      SizedBox(width: 21),
                                                      Text('Sea Tile Removal')
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        height: 20,
                                                        child: Switch(
                                                          value:
                                                              enableTileCompression,
                                                          onChanged: (bool
                                                                  newVal) =>
                                                              setState(() =>
                                                                  enableTileCompression =
                                                                      newVal),
                                                        ),
                                                      ),
                                                      SizedBox(width: 19),
                                                      Text('Tile Compression')
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      minZoomInputController,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    NumericalRangeFormatter(
                                                        min: 1, max: 22),
                                                  ],
                                                  decoration: InputDecoration(
                                                    hintText: '1',
                                                    labelText: 'Minimum Zoom',
                                                  ),
                                                  onChanged: (String newZoom) {
                                                    if (newZoom == '') return;
                                                    setState(() {
                                                      minZoom =
                                                          int.parse(newZoom);
                                                    });
                                                  },
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  textAlign: TextAlign.start,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      maxZoomInputController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    NumericalRangeFormatter(
                                                        min: 1, max: 22),
                                                  ],
                                                  decoration: InputDecoration(
                                                    hintText: '18',
                                                    labelText: 'Maximum Zoom',
                                                  ),
                                                  onChanged: (String newZoom) {
                                                    if (newZoom == '') return;
                                                    setState(() {
                                                      maxZoom =
                                                          int.parse(newZoom);
                                                    });
                                                  },
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectingDownloadRegion =
                                                      null;
                                                  tappedLocations = [];
                                                });
                                              },
                                              child: Text('Cancel'),
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: StreamBuilder<
                                                ConnectivityResult>(
                                              stream: forceUseCellular
                                                  ? Stream.value(
                                                      ConnectivityResult.wifi)
                                                  : Connectivity()
                                                      .onConnectivityChanged,
                                              builder: (context, connectivity) {
                                                if (!connectivity.hasData)
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                if (connectivity.data ==
                                                    ConnectivityResult.none) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Icon(Icons.cloud_off),
                                                        Text(
                                                            'Go online to download map regions'),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                if (connectivity.data ==
                                                    ConnectivityResult.mobile) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Icon(Icons
                                                            .signal_cellular_connected_no_internet_4_bar),
                                                        Text(
                                                          'Are you sure you want\nto use cellular data?',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        TextButton(
                                                          child: Text(
                                                              'Use Cellular Data'),
                                                          onPressed: () {
                                                            setState(() {
                                                              forceUseCellular =
                                                                  true;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: OutlinedButton(
                                                        onPressed: () {
                                                          startDownload(
                                                            dir.data!,
                                                            selectingDownloadRegion ==
                                                                    RegionType
                                                                        .rectangle
                                                                ? RectangleRegion(
                                                                    LatLngBounds(
                                                                        tappedLocations[
                                                                            0],
                                                                        tappedLocations[
                                                                            1]),
                                                                  ).toDownloadable(
                                                                    minZoom,
                                                                    maxZoom,
                                                                    tileLayerOptions,
                                                                    preventRedownload:
                                                                        enablePreventRedownload,
                                                                    seaTileRemoval:
                                                                        enableSeaTileRemoval,
                                                                    compressionQuality:
                                                                        enableTileCompression
                                                                            ? 50
                                                                            : -1,
                                                                  )
                                                                : CircleRegion(
                                                                    tappedLocations[
                                                                        0],
                                                                    Distance().distance(
                                                                            tappedLocations[0],
                                                                            tappedLocations[1]) /
                                                                        1000,
                                                                  ).toDownloadable(
                                                                    minZoom,
                                                                    maxZoom,
                                                                    tileLayerOptions,
                                                                    preventRedownload:
                                                                        enablePreventRedownload,
                                                                    seaTileRemoval:
                                                                        enableSeaTileRemoval,
                                                                    compressionQuality:
                                                                        enableTileCompression
                                                                            ? 50
                                                                            : -1,
                                                                  ),
                                                          );
                                                        },
                                                        child: Text(
                                                            'Start Download'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Expanded(
                                                      flex: 2,
                                                      child: OutlinedButton(
                                                        onPressed:
                                                            Platform.isAndroid
                                                                ? () {
                                                                    StorageCachingTileProvider
                                                                        .requestIgnoreBatteryOptimizations(
                                                                            context);
                                                                    startDownload(
                                                                      dir.data!,
                                                                      selectingDownloadRegion ==
                                                                              RegionType.rectangle
                                                                          ? RectangleRegion(
                                                                              LatLngBounds(tappedLocations[0], tappedLocations[1]),
                                                                            ).toDownloadable(
                                                                              minZoom,
                                                                              maxZoom,
                                                                              tileLayerOptions,
                                                                            )
                                                                          : CircleRegion(
                                                                              tappedLocations[0],
                                                                              Distance().distance(tappedLocations[0], tappedLocations[1]) / 1000,
                                                                            ).toDownloadable(
                                                                              minZoom,
                                                                              maxZoom,
                                                                              tileLayerOptions,
                                                                            ),
                                                                      background:
                                                                          true,
                                                                    );
                                                                  }
                                                                : null,
                                                        child: Text(
                                                            'In Background'),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: downloadInProgress &&
                                          percentageComplete != 0,
                                      child: Column(
                                        children: [
                                          Visibility(
                                            visible: !downloadJustFinished,
                                            child: Column(
                                              children: [
                                                LinearProgressIndicator(
                                                  value:
                                                      percentageComplete / 100,
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text(
                                                          (int.parse(successfulTiles) +
                                                                  int.parse(
                                                                      failedTiles))
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Complete',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        Text(
                                                          successfulTiles,
                                                          style: TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Successful',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        Text(
                                                          failedTiles,
                                                          style: TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                failedTiles !=
                                                                        '0'
                                                                    ? Colors.red
                                                                    : null,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Failed',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color:
                                                                failedTiles !=
                                                                        '0'
                                                                    ? Colors.red
                                                                    : null,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text(
                                                          durationElapsed,
                                                          style: TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Elapsed Duration',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        Text(
                                                          estRemainingDuration,
                                                          style: TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Remaining Duration',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: downloadJustFinished,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  percentageComplete == 100
                                                      ? Icons.done_all
                                                      : Icons.cancel_outlined,
                                                  color:
                                                      percentageComplete == 100
                                                          ? Colors.green
                                                          : Colors.red,
                                                  size: 56,
                                                ),
                                                SizedBox(width: 40),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      successfulTiles,
                                                      style: TextStyle(
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      percentageComplete == 100
                                                          ? failedTiles
                                                          : (percentageComplete
                                                                  .toStringAsFixed(
                                                                      2) +
                                                              '%'),
                                                      style: TextStyle(
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: failedTiles !=
                                                                    '0' &&
                                                                percentageComplete ==
                                                                    100
                                                            ? Colors.red
                                                            : null,
                                                      ),
                                                    ),
                                                    Text(
                                                      durationElapsed,
                                                      style: TextStyle(
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(width: 20),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('successful\ntiles'),
                                                    SizedBox(height: 3),
                                                    Text(
                                                      percentageComplete == 100
                                                          ? 'failed\ntiles'
                                                          : 'completed\npercentage',
                                                      style: TextStyle(
                                                        color: failedTiles !=
                                                                    '0' &&
                                                                percentageComplete ==
                                                                    100
                                                            ? Colors.red
                                                            : null,
                                                      ),
                                                    ),
                                                    SizedBox(height: 3),
                                                    Text('total\nduration'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: downloadJustFinished
                                                  ? null
                                                  : () {
                                                      if (downloadingInBackground)
                                                        cancelBackgroundFlag =
                                                            true;
                                                      else
                                                        downloadProvider!
                                                            .cancelDownload();
                                                      setState(() {
                                                        downloadJustFinished =
                                                            true;
                                                      });
                                                    },
                                              child: Text('Cancel'),
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: !downloadJustFinished
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        downloadInProgress =
                                                            false;
                                                        downloadJustFinished =
                                                            false;
                                                        selectingDownloadRegion =
                                                            null;
                                                        prevTappedLocations =
                                                            [];
                                                        tappedLocations = [];
                                                        successfulTiles = '0';
                                                        failedTiles = '0';
                                                        durationElapsed =
                                                            '0:00:00';
                                                        estRemainingDuration =
                                                            '0:00:00';
                                                        percentageComplete = 0;
                                                        lockPreventRedownload =
                                                            false;
                                                      });
                                                    },
                                              child: Text('Reset'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: downloadInProgress &&
                                          percentageComplete == 0,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 10),
                                          Text(
                                            'Preparing Your Download\nPlease Bear With Us',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                      center: LatLng(51.50497044472158, -0.6690676698303173),
                      zoom: 13.0,
                      interactiveFlags: lockRotation
                          ? InteractiveFlag.all & ~InteractiveFlag.rotate
                          : InteractiveFlag.all,
                      onTap: (LatLng location) {
                        if (selectingDownloadRegion != null) {
                          setState(() {
                            tappedLocations.add(location);
                          });
                          if (tappedLocations.length == 1) return;
                          panelController.open();
                        }
                      }),
                  children: <Widget>[
                    TileLayerWidget(
                      options: tileLayerOptions,
                    ),
                    PolygonLayerWidget(
                      options: selectingDownloadRegion == null ||
                              tappedLocations.length != 2
                          ? PolygonLayerOptions()
                          : selectingDownloadRegion == RegionType.rectangle
                              ? RectangleRegion(
                                  LatLngBounds(
                                      tappedLocations[0], tappedLocations[1]),
                                ).toDrawable(
                                  Colors.green.withAlpha(128),
                                  Colors.green,
                                )
                              : CircleRegion(
                                  tappedLocations[0],
                                  Distance().distance(tappedLocations[0],
                                          tappedLocations[1]) /
                                      1000,
                                ).toDrawable(
                                  Colors.green.withAlpha(128),
                                  Colors.green,
                                ),
                    ),
                  ],
                ),
                FutureBuilder(
                  future: mapController.onReady,
                  builder: (context, _) {
                    return StreamBuilder(
                      stream: mapController.mapEventStream,
                      builder: (context, snapshot) {
                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: animationDurationSlow,
                              curve: animationCurve,
                              right: mapController.rotation == 0 ? -48 : 0,
                              top: 48,
                              child: IgnorePointer(
                                ignoring: mapController.rotation == 0,
                                child: AnimatedOpacity(
                                  duration: animationDuration,
                                  curve: animationCurve,
                                  opacity: mapController.rotation == 0 ? 0 : 1,
                                  child: FloatingActionButton(
                                    mini: true,
                                    onPressed: () => mapController.rotate(0),
                                    child: Icon(Icons.north),
                                    tooltip: 'North Up',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: () => setState(
                                    () => lockRotation = !lockRotation),
                                child: Icon(
                                  lockRotation
                                      ? Icons.screen_lock_rotation
                                      : Icons.screen_rotation,
                                ),
                                tooltip: 'Lock Rotation',
                              ),
                            ),
                            AnimatedPositioned(
                              duration: animationDurationSlow,
                              curve: animationCurve,
                              right: tappedLocations.length != 2 ? -48 : 0,
                              top: mapController.rotation == 0 ? 48 : 96,
                              child: IgnorePointer(
                                ignoring: tappedLocations.length != 2,
                                child: AnimatedOpacity(
                                  duration: animationDuration,
                                  curve: animationCurve,
                                  opacity: tappedLocations.length != 2 ? 0 : 1,
                                  child: FloatingActionButton(
                                    mini: true,
                                    onPressed: () {
                                      mapController.rotate(0);
                                      if (selectingDownloadRegion ==
                                          RegionType.circle)
                                        mapController.fitBounds(
                                          LatLngBounds(
                                            _moveByBottomPadding(
                                              LatLng(
                                                Distance()
                                                    .offset(
                                                      tappedLocations[0],
                                                      Distance().distance(
                                                          tappedLocations[0],
                                                          tappedLocations[1]),
                                                      0,
                                                    )
                                                    .latitude,
                                                Distance()
                                                    .offset(
                                                      tappedLocations[0],
                                                      Distance().distance(
                                                          tappedLocations[0],
                                                          tappedLocations[1]),
                                                      270,
                                                    )
                                                    .longitude,
                                              ),
                                              mapController.zoom,
                                              100,
                                            ),
                                            _moveByBottomPadding(
                                              LatLng(
                                                Distance()
                                                    .offset(
                                                      tappedLocations[0],
                                                      Distance().distance(
                                                          tappedLocations[0],
                                                          tappedLocations[1]),
                                                      180,
                                                    )
                                                    .latitude,
                                                Distance()
                                                    .offset(
                                                      tappedLocations[0],
                                                      Distance().distance(
                                                          tappedLocations[0],
                                                          tappedLocations[1]),
                                                      90,
                                                    )
                                                    .longitude,
                                              ),
                                              mapController.zoom,
                                              100,
                                            ),
                                          ),
                                        );
                                      else
                                        mapController.fitBounds(
                                          LatLngBounds(
                                            _moveByBottomPadding(
                                              tappedLocations[0],
                                              mapController.zoom,
                                              100,
                                            ),
                                            _moveByBottomPadding(
                                              tappedLocations[1],
                                              mapController.zoom,
                                              100,
                                            ),
                                          ),
                                        );
                                    },
                                    child: Icon(Icons.center_focus_strong),
                                    tooltip: 'Focus On Region',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NumericalRangeFormatter extends TextInputFormatter {
  final double min;
  final double max;

  NumericalRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text == '') {
      return newValue;
    } else if (int.parse(newValue.text) < min) {
      return TextEditingValue().copyWith(text: min.toStringAsFixed(2));
    } else {
      return int.parse(newValue.text) > max ? oldValue : newValue;
    }
  }
}

LatLng _moveByBottomPadding(
    LatLng coordinates, double zoomLevel, double bottomOffset) {
  // the following code is copied from unreachable flutter map internas
  final crs = const Epsg3857();
  final oldCenterPt = crs.latLngToPoint(coordinates, zoomLevel);
  final offset = CustomPoint(0, bottomOffset);

  final newCenterPt = oldCenterPt + offset;
  final newCenter = crs.pointToLatLng(newCenterPt, zoomLevel);

  return newCenter!;
}
