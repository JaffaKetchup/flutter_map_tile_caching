import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/screens/home/config_view/panels/stores/state/export_selection_provider.dart';
import 'src/screens/home/home.dart';
import 'src/screens/home/map_view/state/region_selection_provider.dart';
import 'src/screens/initialisation_error/initialisation_error.dart';
import 'src/screens/store_editor/store_editor.dart';
import 'src/shared/misc/shared_preferences.dart';
import 'src/shared/state/general_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sharedPrefs = await SharedPreferences.getInstance();

  Object? initErr;
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (err) {
    initErr = err;
  }

  runApp(_AppContainer(initialisationError: initErr));
}

class _AppContainer extends StatelessWidget {
  const _AppContainer({
    required this.initialisationError,
  });

  final Object? initialisationError;

  static final _routes = <String,
      ({
    Widget Function(BuildContext)? std,
    PageRoute Function(BuildContext, RouteSettings)? custom,
  })>{
    HomeScreen.route: (
      std: (BuildContext context) => const HomeScreen(),
      custom: null,
    ),
    StoreEditorPopup.route: (
      std: null,
      custom: (context, settings) => MaterialPageRoute(
            builder: (context) => const StoreEditorPopup(),
            settings: settings,
            fullscreenDialog: true,
          ),
    ),
    /*
    ProfileScreen.route: (
      std: (BuildContext context) => const ProfileScreen(),
      custom: ({
        required Widget Function(
          BuildContext,
          Animation<double>,
          Animation<double>,
        ) pageBuilder,
        required RouteSettings settings,
      }) =>
          PageRouteBuilder(
            pageBuilder: pageBuilder,
            settings: settings,
            transitionsBuilder: (context, animation, _, child) {
              const begin = Offset(0, 1);
              const end = Offset.zero;
              const curve = Curves.ease;

              final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
    ),*/
  };

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      textTheme: GoogleFonts.ubuntuTextTheme(ThemeData.light().textTheme),
      colorSchemeSeed: Colors.teal,
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Icon(Icons.check)
              : null,
        ),
      ),
    );

    if (initialisationError case final err?) {
      return MaterialApp(
        title: 'FMTC Demo (Initialisation Error)',
        theme: themeData,
        home: InitialisationError(err: err),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GeneralProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExportSelectionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RegionSelectionProvider(),
          lazy: true,
        ),
      ],
      child: MaterialApp(
        title: 'FMTC Demo',
        restorationScopeId: 'FMTC Demo',
        theme: themeData,
        initialRoute: HomeScreen.route,
        onGenerateRoute: (settings) {
          final route = _routes[settings.name]!;
          if (route.custom != null) return route.custom!(context, settings);
          return MaterialPageRoute(builder: route.std!, settings: settings);
        },
      ),
    );
  }
}
