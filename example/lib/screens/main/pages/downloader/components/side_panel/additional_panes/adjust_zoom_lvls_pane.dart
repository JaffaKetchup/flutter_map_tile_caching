part of '../parent.dart';

class AdjustZoomLvlsPane extends StatelessWidget {
  const AdjustZoomLvlsPane({
    super.key,
    required this.layoutDirection,
  });

  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => Consumer<DownloaderProvider>(
        builder: (context, provider, _) => Flex(
          direction: layoutDirection,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.zoom_in),
            const SizedBox.square(dimension: 4),
            Text(provider.maxZoom.toString().padLeft(2, '0')),
            Expanded(
              child: Padding(
                padding: layoutDirection == Axis.vertical
                    ? const EdgeInsets.only(bottom: 6, top: 6)
                    : const EdgeInsets.only(left: 6, right: 6),
                child: RotatedBox(
                  quarterTurns: layoutDirection == Axis.vertical ? 3 : 2,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackShape: _CustomSliderTrackShape(),
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: RangeSlider(
                      values: RangeValues(
                        provider.minZoom.toDouble(),
                        provider.maxZoom.toDouble(),
                      ),
                      onChanged: (v) {
                        provider
                          ..minZoom = v.start.toInt()
                          ..maxZoom = v.end.toInt();
                      },
                      max: 22,
                      divisions: 23,
                    ),
                  ),
                ),
              ),
            ),
            Text(provider.minZoom.toString().padLeft(2, '0')),
            const SizedBox.square(dimension: 4),
            const Icon(Icons.zoom_out),
          ],
        ),
      );
}
