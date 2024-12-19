import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/misc/store_metadata_keys.dart';
import '../../../../../../../shared/state/download_configuration_provider.dart';
import '../../../../../../../shared/state/download_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';

class ConfirmationPanel extends StatefulWidget {
  const ConfirmationPanel({super.key});

  @override
  State<ConfirmationPanel> createState() => _ConfirmationPanelState();
}

class _ConfirmationPanelState extends State<ConfirmationPanel> {
  DownloadableRegion<MultiRegion>? _prevTileCountableRegion;
  late Future<int> _tileCount;

  bool _loadingDownloader = false;

  @override
  Widget build(BuildContext context) {
    final regions = context
        .select<RegionSelectionProvider, Map<BaseRegion, HSLColor>>(
          (p) => p.constructedRegions,
        )
        .keys
        .toList(growable: false);
    final minZoom =
        context.select<DownloadConfigurationProvider, int>((p) => p.minZoom);
    final maxZoom =
        context.select<DownloadConfigurationProvider, int>((p) => p.maxZoom);
    final startTile =
        context.select<DownloadConfigurationProvider, int>((p) => p.startTile);
    final endTile =
        context.select<DownloadConfigurationProvider, int?>((p) => p.endTile);
    final hasSelectedStoreName =
        context.select<DownloadConfigurationProvider, String?>(
              (p) => p.selectedStoreName,
            ) !=
            null;
    final fromRecovery = context.select<DownloadConfigurationProvider, int?>(
      (p) => p.fromRecovery,
    );

    final tileCountableRegion = MultiRegion(regions).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      start: startTile,
      end: endTile,
      options: TileLayer(),
    );
    if (_prevTileCountableRegion == null ||
        tileCountableRegion.originalRegion !=
            _prevTileCountableRegion!.originalRegion ||
        tileCountableRegion.minZoom != _prevTileCountableRegion!.minZoom ||
        tileCountableRegion.maxZoom != _prevTileCountableRegion!.maxZoom ||
        tileCountableRegion.start != _prevTileCountableRegion!.start ||
        tileCountableRegion.end != _prevTileCountableRegion!.end) {
      _prevTileCountableRegion = tileCountableRegion;
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
                      .format(snapshot.requireData),
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
              onPressed: !hasSelectedStoreName || _loadingDownloader
                  ? null
                  : _startDownload,
              label: _loadingDownloader
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : const Text('Start Download'),
              icon: _loadingDownloader ? null : const Icon(Icons.download),
            ),
          ),
          if (fromRecovery != null) ...[
            const SizedBox(height: 4),
            Text(
              'This will delete the recoverable region',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  void _updateTileCount() {
    _tileCount =
        const FMTCStore('').download.countTiles(_prevTileCountableRegion!);
    setState(() {});
  }

  Future<void> _startDownload() async {
    setState(() => _loadingDownloader = true);

    final downloadingProvider = context.read<DownloadingProvider>();
    final regionSelection = context.read<RegionSelectionProvider>();
    final downloadConfiguration = context.read<DownloadConfigurationProvider>();

    final store = FMTCStore(downloadConfiguration.selectedStoreName!);
    final urlTemplate =
        (await store.metadata.read)[StoreMetadataKeys.urlTemplate.key];

    if (!mounted) return;

    final downloadableRegion = MultiRegion(
      regionSelection.constructedRegions.keys.toList(growable: false),
    ).toDownloadable(
      minZoom: downloadConfiguration.minZoom,
      maxZoom: downloadConfiguration.maxZoom,
      start: downloadConfiguration.startTile,
      end: downloadConfiguration.endTile,
      options: TileLayer(
        urlTemplate: urlTemplate,
        userAgentPackageName: 'dev.jaffaketchup.fmtc.demo',
      ),
    );

    final downloadStreams = store.download.startForeground(
      region: downloadableRegion,
      parallelThreads: downloadConfiguration.parallelThreads,
      maxBufferLength: downloadConfiguration.maxBufferLength,
      skipExistingTiles: downloadConfiguration.skipExistingTiles,
      skipSeaTiles: downloadConfiguration.skipSeaTiles,
      retryFailedRequestTiles: downloadConfiguration.retryFailedRequestTiles,
      rateLimit: downloadConfiguration.rateLimit,
    );

    downloadingProvider.assignDownload(
      storeName: downloadConfiguration.selectedStoreName!,
      downloadableRegion: downloadableRegion,
      downloadStreams: downloadStreams,
    );

    if (downloadConfiguration.fromRecovery case final recoveryId?) {
      unawaited(FMTCRoot.recovery.cancel(recoveryId));
      downloadConfiguration.fromRecovery = null;
    }

    // The downloading view is switched to by `assignDownload`, when the first
    // event is recieved from the stream (indicating the preparation is
    // complete and the download is starting).
  }
}
