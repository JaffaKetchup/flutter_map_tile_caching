import 'package:flutter/material.dart';

import 'components/map_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  static const MapView _view = MapView();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _view;
  }

  @override
  bool get wantKeepAlive => true;
}
