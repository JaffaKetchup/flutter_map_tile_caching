import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/download_configuration_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';

class ConfirmationPanel extends StatefulWidget {
  const ConfirmationPanel({super.key});

  @override
  State<ConfirmationPanel> createState() => _ConfirmationPanelState();
}

class _ConfirmationPanelState extends State<ConfirmationPanel> {
  DownloadableRegion<MultiRegion>? _prevDownloadableRegion;
  late Future<int> _tileCount;

  void _updateTileCount() {
    _tileCount = const FMTCStore('').download.check(_prevDownloadableRegion!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final startTile =
        context.select<DownloadConfigurationProvider, int>((p) => p.startTile);
    final endTile =
        context.select<DownloadConfigurationProvider, int?>((p) => p.endTile);
    final hasSelectedStoreName =
        context.select<DownloadConfigurationProvider, String?>(
              (p) => p.selectedStoreName,
            ) !=
            null;

    // Not suitable for download!
    final downloadableRegion = MultiRegion(
      context
          .select<RegionSelectionProvider, Map<BaseRegion, HSLColor>>(
            (p) => p.constructedRegions,
          )
          .keys
          .toList(growable: false),
    ).toDownloadable(
      minZoom:
          context.select<DownloadConfigurationProvider, int>((p) => p.minZoom),
      maxZoom:
          context.select<DownloadConfigurationProvider, int>((p) => p.maxZoom),
      start: startTile,
      end: endTile,
      options: TileLayer(),
    );
    if (_prevDownloadableRegion == null ||
        downloadableRegion.originalRegion !=
            _prevDownloadableRegion!.originalRegion ||
        downloadableRegion.minZoom != _prevDownloadableRegion!.minZoom ||
        downloadableRegion.maxZoom != _prevDownloadableRegion!.maxZoom ||
        downloadableRegion.start != _prevDownloadableRegion!.start ||
        downloadableRegion.end != _prevDownloadableRegion!.end) {
      _prevDownloadableRegion = downloadableRegion;
      _updateTileCount();
    }

    return FutureBuilder(
      future: _tileCount,
      builder: (context, snapshot) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Text(
                '$startTile -',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: startTile == 1
                          ? Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withAlpha(255 ~/ 3)
                          : Colors.amber,
                      fontWeight: startTile == 1 ? null : FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  NumberFormat.decimalPatternDigits(decimalDigits: 0)
                      .format(snapshot.data),
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              Text(
                '  tiles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                '- ${endTile ?? '∞'}',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: endTile == null
                          ? Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withAlpha(255 ~/ 3)
                          : null,
                      fontWeight: startTile == 1 ? null : FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.warning_amber, size: 28),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.amber[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You must abide by your tile server's Terms of "
                              'Service when bulk downloading.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Many servers will '
                              'forbid or heavily restrict this action, as it '
                              'places extra strain on resources. Be respectful, '
                              'and note that you use this functionality at your '
                              'own risk.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: !hasSelectedStoreName ? null : () {},
              label: const Text('Start Download'),
              icon: const Icon(Icons.download),
            ),
          ),
        ],
      ),
    );
  }
}
