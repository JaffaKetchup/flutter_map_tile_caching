import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';

class BufferingConfiguration extends StatelessWidget {
  const BufferingConfiguration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BUFFERING CONFIGURATION'),
          Consumer<DownloadProvider>(
            builder: (context, provider, _) => Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackShape: _CustomTrackShape(),
                        ),
                        child: Slider(
                          value: provider.bufferingAmount
                              .clamp(9, provider.regionTiles ?? 1000)
                              .roundToDouble(),
                          min: 9,
                          max: (provider.regionTiles ?? 1000).toDouble(),
                          onChanged: (value) =>
                              provider.bufferingAmount = value.round(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 25),
                    provider.bufferingAmount == 9
                        ? const Text('Disabled')
                        : provider.bufferingAmount >=
                                (provider.regionTiles ?? 1000)
                            ? const Text('Write Once')
                            : Text('${provider.bufferingAmount} tiles'),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}
