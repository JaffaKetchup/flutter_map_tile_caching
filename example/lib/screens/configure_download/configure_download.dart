import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../main/pages/downloading/state/downloading_provider.dart';
import '../main/pages/region_selection/state/region_selection_provider.dart';
import 'components/numerical_input_row.dart';
import 'components/region_information.dart';
import 'components/section_separator.dart';
import 'components/store_selector.dart';
import 'state/configure_download_provider.dart';

class ConfigureDownloadPopup extends StatelessWidget {
  const ConfigureDownloadPopup({
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
        builder: (context, isReady, _) => Scaffold(
          appBar: AppBar(title: const Text('Configure Bulk Download')),
          floatingActionButton:
              Selector<RegionSelectionProvider, StoreDirectory?>(
            selector: (context, provider) => provider.selectedStore,
            builder: (context, selectedStore, child) =>
                selectedStore == null ? const SizedBox.shrink() : child!,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CAUTION',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.report,
                              color: Colors.red,
                              size: 32,
                            ),
                          ],
                        ),
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
                            skipSeaTiles:
                                configureDownloadProvider.skipSeaTiles,
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
          body: Stack(
            children: [
              Positioned.fill(
                left: 12,
                top: 12,
                right: 12,
                bottom: 12,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegionInformation(
                        region: region,
                        minZoom: minZoom,
                        maxZoom: maxZoom,
                      ),
                      const SectionSeparator(),
                      const StoreSelector(),
                      const SectionSeparator(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CONFIGURE DOWNLOAD OPTIONS'),
                          const SizedBox(height: 16),
                          NumericalInputRow(
                            label: 'Parallel Threads',
                            suffixText: 'threads',
                            value: (provider) => provider.parallelThreads,
                            min: 1,
                            max: 10,
                            onChanged: (provider, value) =>
                                provider.parallelThreads = value,
                          ),
                          const SizedBox(height: 8),
                          NumericalInputRow(
                            label: 'Rate Limit',
                            suffixText: 'max. tiles/second',
                            value: (provider) => provider.rateLimit,
                            min: 5,
                            max: 200,
                            onChanged: (provider, value) =>
                                provider.rateLimit = value,
                          ),
                          const SizedBox(height: 8),
                          NumericalInputRow(
                            label: 'Tile Buffer Length',
                            suffixText: 'max. tiles',
                            value: (provider) => provider.maxBufferLength,
                            min: 0,
                            max: 2000,
                            onChanged: (provider, value) =>
                                provider.maxBufferLength = value,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Skip Existing Tiles'),
                              const Spacer(),
                              Switch(
                                value: context
                                    .select<ConfigureDownloadProvider, bool>(
                                  (provider) => provider.skipExistingTiles,
                                ),
                                onChanged: (val) => context
                                    .read<ConfigureDownloadProvider>()
                                    .skipExistingTiles = val,
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Skip Sea Tiles'),
                              const Spacer(),
                              Switch(
                                value: context.select<ConfigureDownloadProvider,
                                    bool>((provider) => provider.skipSeaTiles),
                                onChanged: (val) => context
                                    .read<ConfigureDownloadProvider>()
                                    .skipSeaTiles = val,
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !isReady,
                  child: GestureDetector(
                    onTap: isReady
                        ? () => context
                            .read<ConfigureDownloadProvider>()
                            .isReady = false
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInCubic,
                      color: isReady
                          ? Colors.black.withOpacity(2 / 3)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
