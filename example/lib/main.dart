import 'package:flutter/widgets.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterMapTileCaching.initialise();
  await FMTC.instance.rootDirectory.migrator.fromV6(
    urlTemplates: null,
  );
  await FMTC.instance.rootDirectory.import.withGUI();
  print('Complete');
}

/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await FlutterMapTileCaching.initialise();
  //await FMTC.instance.directory.migrator.fromV4();

  if (prefs.getBool('reset') ?? false) {
    await FMTC.instance.rootDirectory.manage.reset();

    final instanceA = FMTC.instance('OpenStreetMap (A)');
    await instanceA.manage.create();
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

    final instanceB = FMTC.instance('OpenStreetMap (B)');
    await instanceB.manage.create();
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
*/