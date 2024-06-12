import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/screens/home/home.dart';
import 'src/screens/home/map_view/state/region_selection_provider.dart';
import 'src/screens/initialisation_error/initialisation_error.dart';
import 'src/shared/misc/shared_preferences.dart';
import 'src/shared/state/general_provider.dart';

/*void main() {
  runApp(RootWidget());
}

class RootWidget extends StatelessWidget {
  const RootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeWidget(),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final bottomSheetOuterController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: ColoredBox(
          color: Colors.red,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                print(bottomSheetOuterController.isAttached);
                bottomSheetOuterController.animateTo(
                  0.5,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              },
              child: Text('expand'),
            ),
          ),
        ),
      ),
      bottomSheet: DraggableScrollableSheet(
        initialChildSize: 0.3,
        expand: false,
        controller: bottomSheetOuterController,
        builder: (context, innerController) => ColoredBox(
          color: Colors.blue,
          child: SizedBox.expand(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  print(bottomSheetOuterController.isAttached);
                  bottomSheetOuterController.animateTo(
                    0.5,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                  );
                },
                child: Text('expand'),
              ),
            ),
          ),
        ),
      ),
      /*bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Download',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == 1) {
            bottomSheetOuterController.animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
            );
          } else {
            bottomSheetOuterController.animateTo(
              0.3,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
            );
          }
        },
      ),*/
    );
  }
}

class CustomBottomSheet extends StatefulWidget {
  const CustomBottomSheet({
    super.key,
    required this.controller,
  });

  final DraggableScrollableController controller;

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0,
      snap: true,
      expand: false,
      snapSizes: const [0.3],
      controller: widget.controller,
      builder: (context, innerController) => ColoredBox(
        color: Colors.blue,
        child: SizedBox.expand(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                print(widget.controller.isAttached);
                widget.controller.animateTo(
                  0.5,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              },
              child: Text('expand'),
            ),
          ),
        ),
      ),
      /*    DelayedControllerAttachmentBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          double radius = 18;
          double calcHeight = 0;
    
          if (widget.controller.isAttached) {
            final maxHeight = widget.controller.sizeToPixels(1);
    
            final oldValue = widget.controller.pixels;
            final oldMax = maxHeight;
            final oldMin = maxHeight - radius;
            const newMax = 0.0;
            final newMin = radius;
    
            radius = ((((oldValue - oldMin) * (newMax - newMin)) /
                        (oldMax - oldMin)) +
                    newMin)
                .clamp(0, radius);
    
            calcHeight = screenTopPadding -
                constraints.maxHeight +
                widget.controller.pixels;
          }
    
          return ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
            child: Column(
              children: [
                DelayedControllerAttachmentBuilder(
                  listenable: innerController,
                  builder: (context, _) => SizedBox(
                    height: calcHeight.clamp(0, screenTopPadding),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      color: innerController.hasClients &&
                              innerController.offset != 0
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerLowest
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        child: Stack(
          children: [
            BottomSheetScrollableProvider(
              innerScrollController: innerController,
              child: widget.child,
            ),
            IgnorePointer(
              child: DelayedControllerAttachmentBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  if (!widget.controller.isAttached) {
                    return const SizedBox.shrink();
                  }
    
                  final calcHeight = BottomSheet.topPadding -
                      (screenTopPadding -
                          constraints.maxHeight +
                          widget.controller.pixels);
    
                  return SizedBox(
                    height: calcHeight.clamp(0, BottomSheet.topPadding),
                    width: constraints.maxWidth,
                    child: Semantics(
                      label: MaterialLocalizations.of(context)
                          .modalBarrierDismissLabel,
                      container: true,
                      child: Center(
                        child: Container(
                          height: 4,
                          width: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),*/
    );
  }
}*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sharedPrefs = await SharedPreferences.getInstance();

  Object? initErr;
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (err) {
    initErr = err;
  }

  await const FMTCStore('Test Store').manage.create();

  runApp(_AppContainer(initialisationError: initErr));
}

class _AppContainer extends StatelessWidget {
  const _AppContainer({
    required this.initialisationError,
  });

  final Object? initialisationError;

  static final _routes = <String,
      ({
    PageRouteBuilder<dynamic> Function({
      required Widget Function(
        BuildContext,
        Animation<double>,
        Animation<double>,
      ) pageBuilder,
      required RouteSettings settings,
    })? custom,
    Widget Function(BuildContext) std,
  })>{
    HomeScreen.route: (
      std: (BuildContext context) => const HomeScreen(),
      custom: null,
    ),
    /*ManageOfflineScreen.route: (
      std: (BuildContext context) => ManageOfflineScreen(),
      custom: null,
    ),
    RegionSelectionScreen.route: (
      std: (BuildContext context) => const RegionSelectionScreen(),
      custom: null,
    ),
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
      colorSchemeSeed: Colors.orange,
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
        /*ChangeNotifierProvider(
          create: (_) => MapProvider(),
          lazy: true,
        ),*/
        ChangeNotifierProvider(
          create: (_) => RegionSelectionProvider(),
          lazy: true,
        ), /*
        ChangeNotifierProvider(
          create: (_) => ConfigureDownloadProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadingProvider(),
          lazy: true,
        ),*/
      ],
      child: MaterialApp(
        title: 'FMTC Demo',
        restorationScopeId: 'FMTC Demo',
        theme: themeData,
        initialRoute: HomeScreen.route,
        onGenerateRoute: (settings) {
          final route = _routes[settings.name]!;
          if (route.custom != null) {
            return route.custom!(
              pageBuilder: (context, _, __) => route.std(context),
              settings: settings,
            );
          }
          return MaterialPageRoute(
            builder: route.std,
            settings: settings,
          );
        },
      ),
    );
  }
}
