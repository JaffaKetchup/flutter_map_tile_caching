import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/map.dart';
import 'components/number_input_field.dart';
import 'components/step_builder.dart';

class BulkDownloader extends StatefulWidget {
  const BulkDownloader({Key? key}) : super(key: key);

  @override
  State<BulkDownloader> createState() => _BulkDownloaderState();
}

class _BulkDownloaderState extends State<BulkDownloader> {
  MapCachingManager? mcm;

  int currentStep = 0;
  String? chosenType;

  bool touchingMap = false;
  int touchIndex = 0;

  List<List<double>> rectLatLngs = [
    [0, 0],
    [0, 0]
  ];
  TextEditingController rectNWLatController = TextEditingController();
  TextEditingController rectNWLngController = TextEditingController();
  TextEditingController rectSELatController = TextEditingController();
  TextEditingController rectSELngController = TextEditingController();

  List<List<double>> circleLatLngs = [
    [0, 0],
    [0]
  ];
  TextEditingController circleLatController = TextEditingController();
  TextEditingController circleLngController = TextEditingController();
  TextEditingController circleRadController = TextEditingController();

  String get locationSubtitleText => chosenType == null
      ? 'Enter LatLng values, or choose on the map'
      : chosenType == 'rectangle'
          ? 'Choose the NW and SE coordinates'
          : chosenType == 'circle'
              ? 'Choose the center coordinate and radius (km)'
              : 'Choose the line route coordinates and radius (km)';

  Widget? get locationContent {
    if (chosenType == 'rectangle') return rectLocationContent();
    if (chosenType == 'circle') return circleLocationContent();
  }

  Column rectLocationContent() {
    return Column(
      children: [
        const SizedBox(height: 5),
        Row(
          children: [
            numberInputField(
              label: 'NW Lat',
              onChanged: (newVal) => setState(
                  () => rectLatLngs[0][0] = double.tryParse(newVal) ?? 0),
              controller: rectNWLatController,
            ),
            const SizedBox(width: 5),
            numberInputField(
              label: 'NW Lng',
              onChanged: (newVal) => setState(
                  () => rectLatLngs[0][1] = double.tryParse(newVal) ?? 0),
              controller: rectNWLngController,
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  touchingMap = !touchingMap;
                  touchIndex = 0;
                });
              },
              icon: const Icon(Icons.touch_app),
              visualDensity: VisualDensity.compact,
              splashRadius: 24,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            numberInputField(
              label: 'SE Lat',
              onChanged: (newVal) => setState(
                  () => rectLatLngs[1][0] = double.tryParse(newVal) ?? 0),
              controller: rectSELatController,
            ),
            const SizedBox(width: 5),
            numberInputField(
              label: 'SE Lng',
              onChanged: (newVal) => setState(
                  () => rectLatLngs[1][1] = double.tryParse(newVal) ?? 0),
              controller: rectSELngController,
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  touchingMap = !touchingMap;
                  touchIndex = 1;
                });
              },
              icon: const Icon(Icons.touch_app),
              visualDensity: VisualDensity.compact,
              splashRadius: 24,
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Column circleLocationContent() {
    return Column(
      children: [
        const SizedBox(height: 5),
        Row(
          children: [
            numberInputField(
              label: 'Center Lat',
              onChanged: (newVal) => setState(
                  () => circleLatLngs[0][0] = double.tryParse(newVal) ?? 0),
              controller: circleLatController,
            ),
            const SizedBox(width: 5),
            numberInputField(
              label: 'Center Lng',
              onChanged: (newVal) => setState(
                  () => circleLatLngs[0][1] = double.tryParse(newVal) ?? 0),
              controller: circleLngController,
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  touchingMap = !touchingMap;
                  touchIndex = 0;
                });
              },
              icon: const Icon(Icons.touch_app),
              visualDensity: VisualDensity.compact,
              splashRadius: 24,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            numberInputField(
              label: 'Radius (km)',
              onChanged: (newVal) => setState(
                  () => circleLatLngs[1][0] = double.tryParse(newVal) ?? 0),
              controller: circleRadController,
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  touchingMap = !touchingMap;
                  touchIndex = 1;
                });
              },
              icon: const Icon(Icons.touch_app),
              visualDensity: VisualDensity.compact,
              splashRadius: 24,
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: SafeArea(
        child: Consumer<GeneralProvider>(
          builder: (context, provider, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Flexible(
                  flex: !touchingMap ? 1 : 2,
                  child: MapView(
                    chosenType: chosenType,
                    rectLatLngs: rectLatLngs,
                    circleLatLngs: circleLatLngs,
                    mcm: mcm!,
                    onTap: (pos) {
                      if (!touchingMap) return;

                      if (chosenType == 'rectangle') {
                        if (touchIndex == 0) {
                          rectNWLatController.text = pos.latitude.toString();
                          rectNWLngController.text = pos.longitude.toString();
                          setState(() => rectLatLngs[0][0] = pos.latitude);
                          setState(() => rectLatLngs[0][1] = pos.longitude);
                        }
                        if (touchIndex == 1) {
                          rectSELatController.text = pos.latitude.toString();
                          rectSELngController.text = pos.longitude.toString();
                          setState(() => rectLatLngs[1][0] = pos.latitude);
                          setState(() => rectLatLngs[1][1] = pos.longitude);
                        }
                      }
                      if (chosenType == 'circle') {
                        if (touchIndex == 0) {
                          circleLatController.text = pos.latitude.toString();
                          circleLngController.text = pos.longitude.toString();
                          setState(() => circleLatLngs[0][0] = pos.latitude);
                          setState(() => circleLatLngs[0][1] = pos.longitude);
                        }
                        if (touchIndex == 1) {
                          final double dist = const Distance().distance(
                                LatLng(
                                    circleLatLngs[0][0], circleLatLngs[0][1]),
                                LatLng(pos.latitude, pos.longitude),
                              ) /
                              1000;
                          circleRadController.text = dist.toString();
                          setState(() => circleLatLngs[1][0] = dist);
                        }
                      }

                      setState(() {
                        touchingMap = false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  flex: touchingMap ? 1 : 2,
                  child: SingleChildScrollView(
                    child: Stepper(
                      currentStep: currentStep,
                      steps: stepBuilder(
                        titles: [
                          'Choose a region type',
                          'Choose the ${chosenType ?? 'region'}\'s location',
                        ],
                        subtitles: [
                          'Choose between rectangle, circle, or line',
                          locationSubtitleText,
                        ],
                        contents: [null, locationContent],
                        currentStep: currentStep,
                      ),
                      onStepTapped: (move) {
                        if (move < currentStep) {
                          setState(() => currentStep = move);
                        }
                        if (move == 0) {
                          setState(() {
                            chosenType = null;
                            rectLatLngs = [
                              [0, 0],
                              [0, 0]
                            ];
                            circleLatLngs = [
                              [0, 0],
                              [0]
                            ];
                          });
                        }
                      },
                      onStepContinue: () => setState(() => currentStep++),
                      onStepCancel: () {
                        setState(() => currentStep--);
                        if (currentStep == 0) {
                          setState(() {
                            chosenType = null;
                            rectLatLngs = [
                              [0, 0],
                              [0, 0]
                            ];
                            circleLatLngs = [
                              [0, 0],
                              [0]
                            ];
                          });
                        }
                      },
                      controlsBuilder: (context,
                          {onStepCancel, onStepContinue}) {
                        if (currentStep == 0) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  chosenType = 'rectangle';
                                  onStepContinue!();
                                },
                                child: const Text('RECTANGLE'),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  chosenType = 'circle';
                                  onStepContinue!();
                                },
                                child: const Text('CIRCLE'),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  chosenType = 'line';
                                  onStepContinue!();
                                },
                                child: const Text('LINE'),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: const [],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
