import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'components/map_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  final MapController _mapController = MapController();
  late final MapView view = MapView(mapController: _mapController);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return view;
  }

  @override
  bool get wantKeepAlive => true;
}
