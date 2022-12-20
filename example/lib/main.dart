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

  await FlutterMapTileCaching.initialise();

  if (prefs.getBool('reset') ?? false) {
    await FMTC.instance.rootDirectory.manage.reset();
  }

  final File newAppVersionFile = File(
    p.join(
      // ignore: invalid_use_of_internal_member, invalid_use_of_protected_member
      FMTC.instance.rootDirectory.directory.absolute.path,
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
