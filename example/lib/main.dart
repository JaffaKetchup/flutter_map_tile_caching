import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import 'pages/bulk_downloader/bulk_downloader.dart';
import 'pages/download/download.dart';
import 'pages/home/home.dart';
import 'pages/store_editor/store_editor.dart';
import 'pages/store_manager/store_manager.dart';
import 'state/bulk_download_provider.dart';
import 'state/general_provider.dart';

void main() async {
  FlutterMapTileCaching.initialise(await RootDirectory.normalCache);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FeatureDiscovery(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<GeneralProvider>(
            create: (context) => GeneralProvider(),
          ),
          ChangeNotifierProvider<BulkDownloadProvider>(
            create: (context) => BulkDownloadProvider(),
          ),
        ],
        child: MaterialApp(
          title: 'FMTC Example',
          theme: ThemeData(
            primarySwatch: Colors.orange,
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/storeManager': (context) => const StoreManager(),
            '/storeEditor': (context) => const StoreEditor(),
            '/download': (context) => const DownloadScreen(),
            '/bulkDownloader': (context) => const BulkDownloader(),
          },
        ),
      ),
    );
  }
}
