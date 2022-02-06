import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/bulk_downloader/bulk_downloader.dart';
import 'pages/home/home.dart';
import 'pages/store_editor/store_editor.dart';
import 'pages/store_manager/store_manager.dart';
import 'state/bulk_download_provider.dart';
import 'state/general_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GeneralProvider>(
      create: (context) => GeneralProvider(),
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
          '/bulkDownloader': (context) =>
              ChangeNotifierProvider<BulkDownloadProvider>(
                create: (context) => BulkDownloadProvider(),
                child: const BulkDownloader(),
              ),
        },
      ),
    );
  }
}
