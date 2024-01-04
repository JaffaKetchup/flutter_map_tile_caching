import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../main/pages/downloading/state/downloading_provider.dart';
import '../../main/pages/region_selection/state/region_selection_provider.dart';
import '../state/configure_download_provider.dart';

class StartDownloadButton extends StatelessWidget {
  const StartDownloadButton({
    super.key,
    required this.region,
    required this.minZoom,
    required this.maxZoom,
  });

  final BaseRegion region;
  final int minZoom;
  final int maxZoom;

  @override
  Widget build(BuildContext context) =>
      Selector<ConfigureDownloadProvider, bool>(
        selector: (context, provider) => provider.isReady,
        builder: (context, isReady, _) =>
            Selector<RegionSelectionProvider, FMTCStore?>(
          selector: (context, provider) => provider.selectedStore,
          builder: (context, selectedStore, child) => IgnorePointer(
            ignoring: selectedStore == null,
            child: AnimatedOpacity(
              opacity: selectedStore == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedScale(
                scale: isReady ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInCubic,
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  margin: const EdgeInsets.only(right: 12, left: 32),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "You must abide by your tile server's Terms of Service when bulk downloading. Many servers will forbid or heavily restrict this action, as it places extra strain on resources. Be respectful, and note that you use this functionality at your own risk.",
                        textAlign: TextAlign.end,
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.report, color: Colors.red, size: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
                onPressed: () async {
                  final configureDownloadProvider =
                      context.read<ConfigureDownloadProvider>();

                  if (!isReady) {
                    configureDownloadProvider.isReady = true;
                    return;
                  }

                  final regionSelectionProvider =
                      context.read<RegionSelectionProvider>();
                  final downloadingProvider =
                      context.read<DownloadingProvider>();

                  final navigator = Navigator.of(context);

                  final metadata = await regionSelectionProvider
                      .selectedStore!.metadata.readAsync;

                  downloadingProvider.setDownloadProgress(
                    regionSelectionProvider.selectedStore!.download
                        .startForeground(
                          region: region.toDownloadable(
                            minZoom: minZoom,
                            maxZoom: maxZoom,
                            options: TileLayer(
                              urlTemplate: metadata['sourceURL'],
                              userAgentPackageName:
                                  'dev.jaffaketchup.fmtc.demo',
                            ),
                          ),
                          parallelThreads:
                              configureDownloadProvider.parallelThreads,
                          maxBufferLength:
                              configureDownloadProvider.maxBufferLength,
                          skipExistingTiles:
                              configureDownloadProvider.skipExistingTiles,
                          skipSeaTiles: configureDownloadProvider.skipSeaTiles,
                          rateLimit: configureDownloadProvider.rateLimit,
                        )
                        .asBroadcastStream(),
                  );
                  configureDownloadProvider.isReady = false;

                  navigator.pop();
                },
                label: const Text('Start Download'),
                icon: Icon(isReady ? Icons.save : Icons.arrow_forward),
              ),
            ],
          ),
        ),
      );
}
