import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:tuple/tuple.dart' show Tuple3;

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
        appBar: AppBar(title: Text('Map Caching/Downloading Demo')),
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
  final minZoomController = TextEditingController();
  final maxZoomController = TextEditingController();

  final mapController = MapController();

  LatLngBounds? _selectedBounds;

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
  }

  @override
  void dispose() {
    northController.dispose();
    eastController.dispose();
    westController.dispose();
    southController.dispose();
    minZoomController.dispose();
    maxZoomController.dispose();
    super.dispose();
  }

  void _handleBoundsInput() {
    final north =
        double.tryParse(northController.text) ?? _selectedBounds?.north;
    final east = double.tryParse(eastController.text) ?? _selectedBounds?.east;
    final west = double.tryParse(westController.text) ?? _selectedBounds?.west;
    final south =
        double.tryParse(southController.text) ?? _selectedBounds?.south;
    if (north == null || east == null || west == null || south == null) {
      return;
    }
    final sw = LatLng(south, west);
    final ne = LatLng(north, east);
    final bounds = LatLngBounds(sw, ne);
    if (!bounds.isValid) return;
    setState(() => _selectedBounds = bounds);
  }

  void _showErrorSnack(String errorMessage) async {
    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    });
  }

  Future<void> _loadMap(
      StorageCachingTileProvider tileProvider, TileLayerOptions options) async {
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
    if (_selectedBounds == null) {
      _showErrorSnack('Invalid bounds area. Area bounds must be defined.');
      return;
    }
    final approximateTileCount =
        StorageCachingTileProvider.approximateTileRange(
                bounds: _selectedBounds!, minZoom: zoomMin, maxZoom: zoomMax)
            .length;
    if (approximateTileCount >
        StorageCachingTileProvider.kMaxPreloadTileAreaCount) {
      _showErrorSnack(
          '$approximateTileCount exceeds maximum number of pre-cachable tiles (${StorageCachingTileProvider.kMaxPreloadTileAreaCount}). Try a smaller amount first.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Downloading Area...'),
        content: StreamBuilder<Tuple3<int, List<String>, int>>(
          initialData: Tuple3(0, [], 0),
          stream: tileProvider.loadTiles(
              _selectedBounds!, zoomMin, zoomMax, options),
          builder: (ctx, snapshot) {
            if (snapshot.hasError) {
              return Text('error: ${snapshot.error.toString()}');
            }
            if (snapshot.connectionState == ConnectionState.done) {
              Navigator.of(ctx).pop();
            }
            final tileIndex = snapshot.data?.item1 ?? 0;
            final tilesAmount = snapshot.data?.item3 ?? 0;
            final tilesErrored = snapshot.data?.item2 ?? [];
            return getLoadProgresWidget(
                ctx, tileIndex, tilesAmount, tilesErrored);
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
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
    mapController.fitBounds(_selectedBounds!,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('BOUNDS', style: Theme.of(context).textTheme.subtitle1),
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
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            controller: westController,
                          ),
                        ),
                        SizedBox(
                          width: boundsInputSize,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'east'),
                            inputFormatters: [decimalInputFormatter],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
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
      int tileAmount, List<String> tilesErrored) {
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
                  value: tileIndex / tileAmount,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  (tileIndex / tileAmount * 100).toInt().toString() + '%',
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
          '${tilesErrored.length == 0 ? '' : ((tileIndex - tilesErrored.length).toString() + '/')}$tileIndex/$tileAmount\nPlease Wait',
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
              center: LatLng(55.753215, 37.622504),
              maxZoom: 18.0,
              zoom: 13.0,
            ),
            layers: [
              tileLayerOptions,
              PolygonLayerOptions(
                polygons: _selectedBounds == null
                    ? []
                    : [
                        Polygon(
                          color: Colors.red.withAlpha(128),
                          borderColor: Colors.red,
                          borderStrokeWidth: 3,
                          points: [
                            _selectedBounds!.southWest!,
                            _selectedBounds!.southEast,
                            _selectedBounds!.northEast!,
                            _selectedBounds!.northWest
                          ],
                        )
                      ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
          child:
              Text('Define area bounds and zoom levels for tile downloading'),
        ),
        getBoundsInputWidget(context),
        Container(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _deleteCachedMap,
              ),
              IconButton(
                icon: Icon(Icons.cloud_download),
                onPressed: () => _loadMap(tileProvider, tileLayerOptions),
              ),
              IconButton(
                icon: Icon(Icons.filter_center_focus),
                onPressed: _selectedBounds == null ? null : _focusToBounds,
              )
            ],
          ),
        ),
      ],
    );
  }
}
