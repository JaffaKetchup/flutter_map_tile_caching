import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/map.dart';
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

  double mapHeight = 300;

  String get locationSubtitleText => chosenType == null
      ? 'Enter LatLng values, or choose on the map'
      : chosenType == 'rectangle'
          ? 'Choose the NW and SE coordinates'
          : chosenType == 'circle'
              ? 'Choose the center coordinate and radius (km)'
              : 'Choose the line route coordinates and radius (km)';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Consumer<GeneralProvider>(
        builder: (context, provider, _) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              AnimatedContainer(
                height: mapHeight,
                child: const MapView(),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              const SizedBox(height: 10),
              Stepper(
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
                  contents: [null, null],
                  currentStep: currentStep,
                ),
                onStepTapped: (move) {
                  if (move < currentStep) setState(() => currentStep = move);
                  if (move == 0) setState(() => chosenType = null);
                },
                onStepContinue: () => setState(() => currentStep++),
                onStepCancel: () {
                  setState(() => currentStep--);
                  if (currentStep == 0) setState(() => chosenType = null);
                },
                controlsBuilder: (context, {onStepCancel, onStepContinue}) {
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
                      children: [],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
