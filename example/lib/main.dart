import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/main/main.dart';
import 'shared/state/general_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  FlutterMapTileCaching.initialise(await RootDirectory.normalCache);
  await FMTC.instance.rootDirectory.manage.resetAsync();

  final StoreDirectory instanceA = FMTC.instance('Store Alpha');
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

  final StoreDirectory instanceB = FMTC.instance('Store Beta');
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
        ],
        child: MaterialApp(
          title: 'FMTC Example',
          theme: ThemeData(
            primarySwatch: Colors.purple,
            useMaterial3: true,
            textTheme: GoogleFonts.openSansTextTheme(),
          ),
          debugShowCheckedModeBanner: false,
          home: const MainScreen(),
        ),
      );
}
