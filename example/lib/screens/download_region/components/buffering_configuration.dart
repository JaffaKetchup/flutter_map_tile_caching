import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';

class BufferingConfiguration extends StatelessWidget {
  const BufferingConfiguration({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DownloadProvider>(
        builder: (context, provider, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BUFFERING CONFIGURATION'),
            if (provider.regionTiles == null)
              const CircularProgressIndicator()
            else
              Builder(
                builder: (context) {
                  final max = (provider.regionTiles! / 2).floorToDouble();
                  return Slider(
                    value: provider.bufferingAmount.clamp(0, max).toDouble(),
                    max: max,
                    divisions: (max / 10).ceil(),
                    onChanged: (value) =>
                        provider.bufferingAmount = value.clamp(0, max).round(),
                    label: provider.bufferingAmount == 0
                        ? 'Disabled'
                        : 'Write every ${provider.bufferingAmount} tiles',
                  );
                },
              ),
          ],
        ),
      );
}
