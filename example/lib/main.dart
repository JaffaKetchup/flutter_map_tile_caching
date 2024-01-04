import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'screens/configure_download/state/configure_download_provider.dart';
import 'screens/main/main.dart';
import 'screens/main/pages/downloading/state/downloading_provider.dart';
import 'screens/main/pages/map/state/map_provider.dart';
import 'screens/main/pages/region_selection/state/region_selection_provider.dart';
import 'shared/state/general_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  String? damagedDatabaseDeleted;
  await FlutterMapTileCaching.initialise();

  await FMTC.instance.rootDirectory.migrator.fromV6(urlTemplates: []);

  final newAppVersionFile = File(
    p.join(
      // ignore: invalid_use_of_internal_member, invalid_use_of_protected_member
      FMTC.instance.rootDirectory.directory.absolute.path,
      'newAppVersion.${Platform.isWindows ? 'exe' : 'apk'}',
    ),
  );
  if (await newAppVersionFile.exists()) await newAppVersionFile.delete();

  runApp(AppContainer(damagedDatabaseDeleted: damagedDatabaseDeleted));
}

class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    required this.damagedDatabaseDeleted,
  });

  final String? damagedDatabaseDeleted;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GeneralProvider()),
          ChangeNotifierProvider(
            create: (_) => MapProvider(),
            lazy: true,
          ),
          ChangeNotifierProvider(
            create: (_) => RegionSelectionProvider(),
            lazy: true,
          ),
          ChangeNotifierProvider(
            create: (_) => ConfigureDownloadProvider(),
            lazy: true,
          ),
          ChangeNotifierProvider(
            create: (_) => DownloadingProvider(),
            lazy: true,
          ),
        ],
        child: MaterialApp(
          title: 'FMTC Demo',
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            textTheme: GoogleFonts.ubuntuTextTheme(const TextTheme()),
            colorSchemeSeed: Colors.red,
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
