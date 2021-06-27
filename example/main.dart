import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart' show LatLng;

void main() {
  runApp(DemoApp());
}

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Caching Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AutoCachedTilesPage(),
    );
  }
}

class AutoCachedTilesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Map Downloading & Painting Demo')),
        body: _AutoCachedTilesPageContent());
  }
}

class _AutoCachedTilesPageContent extends StatefulWidget {
  @override
  _AutoCachedTilesPageContentState createState() =>
      _AutoCachedTilesPageContentState();
}

class _AutoCachedTilesPageContentState
    extends State<_AutoCachedTilesPageContent> {
  final northController = TextEditingController();
  final eastController = TextEditingController();
  final westController = TextEditingController();
  final southController = TextEditingController();
  final centerLatController = TextEditingController();
  final centerLngController = TextEditingController();
  final radiusController = TextEditingController();
  final minZoomController = TextEditingController();
  final maxZoomController = TextEditingController();

  late final MapController mapController;

  LatLngBounds? _selectedBoundsSqr;
  List<double>? _selectedBoundsCir;
  RegionType selectedType = RegionType.circle;

  final decimalInputFormatter = FilteringTextInputFormatter(
      RegExp(r'^-?\d{0,3}\.?\d{0,6}$'),
      allow: true);

  @override
  void initState() {
    super.initState();
    northController.addListener(_handleBoundsInput);
    eastController.addListener(_handleBoundsInput);
    westController.addListener(_handleBoundsInput);
    southController.addListener(_handleBoundsInput);
    centerLatController.addListener(_handleCircleInput);
    centerLngController.addListener(_handleCircleInput);
    radiusController.addListener(_handleCircleInput);
    mapController = MapController();
  }

  @override
  void dispose() {
    northController.dispose();
    eastController.dispose();
    westController.dispose();
    southController.dispose();
    centerLatController.dispose();
    centerLngController.dispose();
    radiusController.dispose();
    minZoomController.dispose();
    maxZoomController.dispose();
    super.dispose();
  }

  void _handleBoundsInput() {
    final north =
        double.tryParse(northController.text) ?? _selectedBoundsSqr?.north;
    final east =
        double.tryParse(eastController.text) ?? _selectedBoundsSqr?.east;
    final west =
        double.tryParse(westController.text) ?? _selectedBoundsSqr?.west;
    final south =
        double.tryParse(southController.text) ?? _selectedBoundsSqr?.south;
    if (north == null || east == null || west == null || south == null) {
      return;
    }
    final sw = LatLng(south, west);
    final ne = LatLng(north, east);
    final bounds = LatLngBounds(sw, ne);
    if (!bounds.isValid) return;
    setState(() => _selectedBoundsSqr = bounds);
  }

  void _handleCircleInput() {
    final lat =
        double.tryParse(centerLatController.text) ?? _selectedBoundsCir?[0];
    final lng =
        double.tryParse(centerLngController.text) ?? _selectedBoundsCir?[1];
    final rad =
        double.tryParse(radiusController.text) ?? _selectedBoundsCir?[2];
    if (lat == null || lng == null || rad == null) {
      return;
    }
    setState(() => _selectedBoundsCir = [lat, lng, rad]);
  }

  void _showErrorSnack(String errorMessage) async {
    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    });
  }

  Future<void> _loadMap(
    StorageCachingTileProvider tileProvider,
    TileLayerOptions options,
    bool background,
  ) async {
    _hideKeyboard();
    final zoomMin = int.tryParse(minZoomController.text);
    if (zoomMin == null) {
      _showErrorSnack(
          'Invalid zoom level. Minimum zoom level must be defined.');
      return;
    }
    final zoomMax = int.tryParse(maxZoomController.text) ?? zoomMin;
    if (zoomMin < 1 || zoomMin > 19 || zoomMax < 1 || zoomMax > 19) {
      _showErrorSnack(
          'Invalid zoom level. Must be inside 1-19 range (inclusive).');
      return;
    }
    if (zoomMax < zoomMin) {
      _showErrorSnack(
          'Invalid zoom level. Maximum zoom must be larger than or equal to minimum zoom.');
      return;
    }
    if ((_selectedBoundsSqr == null && selectedType == RegionType.rectangle) ||
        (_selectedBoundsCir == null && selectedType == RegionType.circle)) {
      _showErrorSnack('Invalid bounds area. Region bounds must be defined.');
      return;
    }
    if (selectedType == RegionType.circle) {
      final approximateTileCount = StorageCachingTileProvider.checkRegion(
        CircleRegion(
          LatLng(_selectedBoundsCir![0], _selectedBoundsCir![1]),
          _selectedBoundsCir![2],
        ).toDownloadable(zoomMin, zoomMax, options),
      );
      if (approximateTileCount >
          StorageCachingTileProvider.kMaxPreloadTileAreaCount) {
        _showErrorSnack(
            '$approximateTileCount exceeds maximum number of pre-cachable tiles (${StorageCachingTileProvider.kMaxPreloadTileAreaCount}). Try a smaller amount first.');
        return;
      }
    } else if (selectedType == RegionType.rectangle) {
      final approximateTileCount = StorageCachingTileProvider.checkRegion(
        RectangleRegion(_selectedBoundsSqr!)
            .toDownloadable(zoomMin, zoomMax, options),
      );
      if (approximateTileCount >
          StorageCachingTileProvider.kMaxPreloadTileAreaCount) {
        _showErrorSnack(
            '$approximateTileCount exceeds maximum number of pre-cachable tiles (${StorageCachingTileProvider.kMaxPreloadTileAreaCount}). Try a smaller amount first.');
        return;
      }
    } else {
      throw UnimplementedError();
    }
    if (!background)
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Downloading Area...'),
          content: StreamBuilder<DownloadProgress>(
            initialData: DownloadProgress.placeholder(),
            stream: (selectedType == RegionType.rectangle
                ? tileProvider.downloadRegion(
                    RectangleRegion(_selectedBoundsSqr!)
                        .toDownloadable(zoomMin, zoomMax, options))
                : (selectedType == RegionType.circle
                    ? tileProvider.downloadRegion(
                        CircleRegion(
                          LatLng(
                              _selectedBoundsCir![0], _selectedBoundsCir![1]),
                          _selectedBoundsCir![2],
                        ).toDownloadable(zoomMin, zoomMax, options),
                      )
                    : null)),
            builder: (ctx, snapshot) {
              if (snapshot.hasError) {
                return Text('error: ${snapshot.error.toString()}');
              }
              final tileIndex = snapshot.data?.completedTiles ?? 0;
              final tilesAmount = snapshot.data?.totalTiles ?? 0;
              final tilesErrored = snapshot.data?.erroredTiles ?? [];
              final progressPercentage = snapshot.data?.percentageProgress ?? 0;
              return getLoadProgresWidget(ctx, tileIndex, tilesAmount,
                  tilesErrored, progressPercentage);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel & Exit'),
              onPressed: () => Navigator.of(ctx).pop(),
            )
          ],
        ),
      );
    else {
      tileProvider.downloadRegionBackground(
        (selectedType == RegionType.rectangle
            ? RectangleRegion(_selectedBoundsSqr!)
                .toDownloadable(zoomMin, zoomMax, options)
            : (selectedType == RegionType.circle
                ? CircleRegion(
                    LatLng(_selectedBoundsCir![0], _selectedBoundsCir![1]),
                    _selectedBoundsCir![2],
                  ).toDownloadable(zoomMin, zoomMax, options)
                : null))!,
      );
    }
  }

  Future<void> _deleteCachedMap() async {
    _hideKeyboard();
    final currentCacheSize =
        await TileStorageCachingManager.cacheDbSize / 1024 / 1024;
    final currentCacheAmount =
        await TileStorageCachingManager.cachedTilesAmount;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Cache'),
        content:
            Text('Total Cache Size: ${currentCacheSize.toStringAsFixed(2)} MB'
                '\nTotal Cached Tiles: $currentCacheAmount'
                '\nAre you sure you want to clear the cache?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Clear Cache'),
            onPressed: () => Navigator.pop(context, true),
          )
        ],
      ),
    );
    if (result == true) {
      await TileStorageCachingManager.cleanCache();
      _showErrorSnack('Cache cleared successfully');
    }
  }

  void _hideKeyboard() => FocusScope.of(context).requestFocus(FocusNode());

  void _focusToBounds() {
    _hideKeyboard();
    mapController.fitBounds(_selectedBoundsSqr!,
        options: FitBoundsOptions(padding: EdgeInsets.all(32)));
  }

  Widget getBoundsInputWidget(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boundsSectionWidth = size.width * 0.8;
    final zoomSectionWidth = size.width - boundsSectionWidth;
    final boundsInputSize = boundsSectionWidth / 2 - 4 * 16;
    final zoomInputWidth = zoomSectionWidth - 32;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: selectedType == RegionType.circle
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('BOUNDS',
                            style: Theme.of(context).textTheme.subtitle1),
                        Row(
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: (boundsSectionWidth / 4 * 1.6) - 7.2,
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    decoration:
                                        InputDecoration(hintText: 'Center Lat'),
                                    inputFormatters: [decimalInputFormatter],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    controller: centerLatController,
                                  ),
                                ),
                                SizedBox(
                                  width: (boundsSectionWidth / 4 * 1.6) - 7.2,
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    decoration:
                                        InputDecoration(hintText: 'Center Lng'),
                                    inputFormatters: [decimalInputFormatter],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    controller: centerLngController,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 20),
                            SizedBox(
                              width: (boundsSectionWidth / 4 * 1.6) - 7.2,
                              child: TextField(
                                textAlign: TextAlign.center,
                                decoration:
                                    InputDecoration(hintText: 'Radius (km)'),
                                inputFormatters: [decimalInputFormatter],
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                controller: radiusController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('BOUNDS',
                            style: Theme.of(context).textTheme.subtitle1),
                        SizedBox(
                          width: boundsInputSize,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'north'),
                            inputFormatters: [decimalInputFormatter],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            controller: northController,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              SizedBox(
                                width: boundsInputSize,
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(hintText: 'west'),
                                  inputFormatters: [decimalInputFormatter],
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  controller: westController,
                                ),
                              ),
                              SizedBox(
                                width: boundsInputSize,
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(hintText: 'east'),
                                  inputFormatters: [decimalInputFormatter],
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  controller: eastController,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: boundsInputSize,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'south'),
                            inputFormatters: [decimalInputFormatter],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            controller: southController,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Container(
            padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('ZOOM', style: Theme.of(context).textTheme.subtitle1),
                SizedBox(
                  width: zoomInputWidth,
                  child: TextField(
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration:
                        InputDecoration(counterText: '', hintText: 'min'),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: false),
                    controller: minZoomController,
                  ),
                ),
                SizedBox(
                  width: zoomInputWidth,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'max',
                    ),
                    maxLength: 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: false),
                    controller: maxZoomController,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget getLoadProgresWidget(BuildContext context, int tileIndex,
      int tileAmount, List<String> tilesErrored, double progress) {
    if (tileAmount == 0) {
      tileAmount = 1;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  backgroundColor: Colors.grey,
                  value: progress / 100,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  progress == 100.0
                      ? '100%'
                      : (progress.toStringAsFixed(1) + '%'),
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          progress == 100.0
              ? 'Download Finished'
              : '${tilesErrored.length == 0 ? '' : ((tileIndex - tilesErrored.length).toString() + '/')}$tileIndex/$tileAmount\nPlease Wait',
          style: Theme.of(context).textTheme.subtitle2,
          textAlign: TextAlign.center,
        ),
        Visibility(
          visible: tilesErrored.length != 0,
          child: Expanded(
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  'Errored Tiles: ${tilesErrored.length}',
                  style: Theme.of(context).textTheme.subtitle2!.merge(TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      )),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Expanded(
                  child: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        String test = '';
                        try {
                          test = tilesErrored.reversed.toList()[index];
                        } catch (e) {} finally {
                          // ignore: control_flow_in_finally
                          return Column(
                            children: [
                              Text(
                                test
                                    .replaceAll('https://', '')
                                    .replaceAll('http://', '')
                                    .split('/')[0],
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .merge(TextStyle(color: Colors.red)),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                test
                                    .replaceAll(
                                        test
                                            .replaceAll('https://', '')
                                            .replaceAll('http://', '')
                                            .split('/')[0],
                                        '')
                                    .replaceAll('https:///', '')
                                    .replaceAll('http:///', ''),
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .merge(TextStyle(color: Colors.red)),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileProvider = StorageCachingTileProvider();
    final tileLayerOptions = TileLayerOptions(
      tileProvider: tileProvider,
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
    );
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(51.49990436717166, -0.6769064891560369),
              maxZoom: 19.0,
              zoom: 13.0,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            layers: [
              tileLayerOptions,
              _selectedBoundsSqr == null
                  ? PolygonLayerOptions()
                  : RectangleRegion(
                      _selectedBoundsSqr!,
                    ).toDrawable(
                      Colors.green.withAlpha(128),
                      Colors.green,
                    ),
              _selectedBoundsCir == null
                  ? PolygonLayerOptions()
                  : CircleRegion(
                      LatLng(_selectedBoundsCir![0], _selectedBoundsCir![1]),
                      _selectedBoundsCir![2],
                    ).toDrawable(
                      Colors.green.withAlpha(128),
                      Colors.green,
                    ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(
            'Define region bounds and zoom levels for painting and downloading',
            textAlign: TextAlign.center,
          ),
        ),
        getBoundsInputWidget(context),
        Container(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  selectedType == RegionType.circle
                      ? Icons.add_circle
                      : Icons.add_circle_outline,
                  color:
                      selectedType == RegionType.circle ? Colors.green : null,
                ),
                onPressed: () => setState(() {
                  selectedType = RegionType.circle;
                }),
              ),
              IconButton(
                icon: Icon(
                  selectedType == RegionType.rectangle
                      ? Icons.add_box
                      : Icons.add_box_outlined,
                  color: selectedType == RegionType.rectangle
                      ? Colors.green
                      : null,
                ),
                onPressed: () => setState(() {
                  selectedType = RegionType.rectangle;
                }),
              ),
              IconButton(
                icon: Icon(
                  selectedType == RegionType.line
                      ? Icons.auto_graph_outlined
                      : Icons.show_chart,
                  color: selectedType == RegionType.line ? Colors.green : null,
                ),
                onPressed: () => setState(() {
                  selectedType = RegionType.line;
                }),
              ),
              IconButton(
                icon: Icon(
                  selectedType == RegionType.customPolygon
                      ? Icons.edit
                      : Icons.edit_off_outlined,
                  color: selectedType == RegionType.customPolygon
                      ? Colors.green
                      : null,
                ),
                onPressed: () => setState(() {
                  selectedType = RegionType.customPolygon;
                }),
              ),
              VerticalDivider(
                indent: 10,
                endIndent: 10,
                width: 0,
                thickness: 1,
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _deleteCachedMap,
              ),
              IconButton(
                icon: Icon(Icons.filter_center_focus),
                onPressed: _selectedBoundsSqr == null ||
                        selectedType != RegionType.rectangle
                    ? null
                    : _focusToBounds,
              ),
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () {
                  _loadMap(tileProvider, tileLayerOptions, false);
                },
              ),
              IconButton(
                icon: Icon(Icons.downloading),
                onPressed: () {
                  _loadMap(tileProvider, tileLayerOptions, true);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
