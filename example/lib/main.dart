import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main/main.dart';
import 'shared/state/download_provider.dart';
import 'shared/state/general_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  FlutterMapTileCaching.initialise(await RootDirectory.normalCache);
  await FMTC.instance.rootDirectory.migrator.fromV4();

  if (prefs.getBool('reset') ?? false) {
    await FMTC.instance.rootDirectory.manage.resetAsync();

    final StoreDirectory instanceA = FMTC.instance('OpenStreetMap (A)');
    await instanceA.manage.createAsync();
    await instanceA.metadata.addAsync(
      key: 'sourceURL',
      value: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    await instanceA.metadata.addAsync(
      key: 'validDuration',
      value: '14',
    );
    await instanceA.metadata.addAsync(
      key: 'behaviour',
      value: 'cacheFirst',
    );

    final StoreDirectory instanceB = FMTC.instance('OpenStreetMap (B)');
    await instanceB.manage.createAsync();
    await instanceB.metadata.addAsync(
      key: 'sourceURL',
      value: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    await instanceB.metadata.addAsync(
      key: 'validDuration',
      value: '14',
    );
    await instanceB.metadata.addAsync(
      key: 'behaviour',
      value: 'cacheFirst',
    );
  }

  final File newAppVersionFile = File(
    p.join(
      FMTC.instance.rootDirectory.access.real.path,
      'newAppVersion.${Platform.isWindows ? 'exe' : 'apk'}',
    ),
  );
  if (await newAppVersionFile.exists()) await newAppVersionFile.delete();

  runApp(const AppContainer());
}

class AppContainer extends StatelessWidget {
  const AppContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<GeneralProvider>(
            create: (context) => GeneralProvider(),
          ),
          ChangeNotifierProvider<DownloadProvider>(
            create: (context) => DownloadProvider(),
          ),
        ],
        child: MaterialApp(
          title: 'FMTC Example',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.teal,
              accentColor: Colors.deepOrange,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.openSansTextTheme(),
          ),
          debugShowCheckedModeBanner: false,
          home: const MainScreen(),
        ),
      );
}
