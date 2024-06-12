part of '../parent.dart';

class LineRegionPane extends StatelessWidget {
  const LineRegionPane({
    super.key,
    required this.layoutDirection,
  });

  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => Consumer<RegionSelectionProvider>(
        builder: (context, provider, _) => Flex(
          direction: layoutDirection,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                final provider = context.read<RegionSelectionProvider>();

                if (Platform.isAndroid || Platform.isIOS) {
                  await FilePicker.platform.clearTemporaryFiles();
                }

                late final FilePickerResult? result;
                try {
                  result = await FilePicker.platform.pickFiles(
                    dialogTitle: 'Parse From GPX',
                    type: FileType.custom,
                    allowedExtensions: ['gpx', 'kml'],
                    allowMultiple: true,
                  );
                } on PlatformException catch (_) {
                  result = await FilePicker.platform.pickFiles(
                    dialogTitle: 'Parse From GPX',
                    allowMultiple: true,
                  );
                }

                if (result != null) {
                  final gpxReader = GpxReader();
                  for (final path in result.files.map((e) => e.path)) {
                    provider.addCoordinates(
                      gpxReader
                          .fromString(
                            await File(path!).readAsString(),
                          )
                          .trks
                          .map(
                            (e) => e.trksegs.map(
                              (e) => e.trkpts.map(
                                (e) => LatLng(e.lat!, e.lon!),
                              ),
                            ),
                          )
                          .expand((e) => e)
                          .expand((e) => e),
                    );
                  }
                }
              },
              icon: const Icon(Icons.route),
              tooltip: 'Import from GPX',
            ),
            if (layoutDirection == Axis.vertical)
              const Divider(height: 8)
            else
              const VerticalDivider(width: 8),
            const SizedBox.square(dimension: 4),
            if (layoutDirection == Axis.vertical) ...[
              Text('${provider.lineRadius.round()}m'),
              const Text('radius'),
            ],
            if (layoutDirection == Axis.horizontal)
              Text('${provider.lineRadius.round()}m radius'),
            Expanded(
              child: Padding(
                padding: layoutDirection == Axis.vertical
                    ? const EdgeInsets.only(bottom: 12, top: 28)
                    : const EdgeInsets.only(left: 28, right: 12),
                child: RotatedBox(
                  quarterTurns: layoutDirection == Axis.vertical ? 3 : 0,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackShape: _CustomSliderTrackShape(),
                    ),
                    child: Slider(
                      value: provider.lineRadius,
                      onChanged: (v) => provider.lineRadius = v,
                      min: 100,
                      max: 4000,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
