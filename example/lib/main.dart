import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  //final SharedPreferences prefs = await SharedPreferences.getInstance();

  // String? damagedDatabaseDeleted;
  await FlutterMapTileCaching.initialise(
    // errorHandler: (error) => damagedDatabaseDeleted = error.message,
    debugMode: true,
  );

  // await FMTC.instance.rootDirectory.migrator.fromV6(urlTemplates: []);

  //if (prefs.getBool('reset') ?? false) {
  //  await FMTC.instance.rootDirectory.manage.reset();
  // }

  //final File newAppVersionFile = File(
  //   p.join(
  //     // ignore: invalid_use_of_internal_member, invalid_use_of_protected_member
  //     FMTC.instance.rootDirectory.directory.absolute.path,
  //     'newAppVersion.${Platform.isWindows ? 'exe' : 'apk'}',
  //  ),
  // );
  // if (await newAppVersionFile.exists()) await newAppVersionFile.delete();

  final region =
      RectangleRegion(LatLngBounds(const LatLng(1, 1), const LatLng(-1, -1)))
          .toDownloadable(
    1,
    12,
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.jaffaketchup.fmtc.demo1',
    ),
  );

  FMTC.instance['hello'].download
      .startForeground(
        region: region,
        pruneExistingTiles: false,
        pruneSeaTiles: false,
        maxBufferLength: 200,
      )
      .listen(
        (progress) => print(
          '${progress.successfulTiles} tiles, ${progress.duration}, ${progress.lastTileEvent?.result}',
        ),
      );
  print('DOWNLOAD COMPLETE');

  await Future.delayed(const Duration(seconds: 1));

  print('REQUEST CANCEL');
  await FMTC.instance['hello'].download.cancel();
  print('DOWNLOAD CANCELLED');

  //runApp(AppContainer(damagedDatabaseDeleted: damagedDatabaseDeleted));
}

/*class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    required this.damagedDatabaseDeleted,
  });

  final String? damagedDatabaseDeleted;

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
            brightness: Brightness.dark,
            useMaterial3: true,
            textTheme: GoogleFonts.openSansTextTheme(const TextTheme()),
            colorSchemeSeed: Colors.deepOrange,
            switchTheme: SwitchThemeData(
              thumbIcon: MaterialStateProperty.resolveWith(
                (states) => Icon(
                  states.contains(MaterialState.selected)
                      ? Icons.check
                      : Icons.close,
                ),
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: MainScreen(damagedDatabaseDeleted: damagedDatabaseDeleted),
        ),
      );
}
*/