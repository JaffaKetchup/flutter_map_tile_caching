import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  MapCachingManager? mcm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm = ModalRoute.of(context)!.settings.arguments as MapCachingManager?;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
