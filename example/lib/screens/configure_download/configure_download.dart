import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/misc/exts/interleave.dart';
import 'components/numerical_input_row.dart';
import 'components/options_pane.dart';
import 'components/region_information.dart';
import 'components/start_download_button.dart';
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Configure Bulk Download')),
        floatingActionButton: StartDownloadButton(
          region: region,
          minZoom: minZoom,
          maxZoom: maxZoom,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox.shrink(),
                    RegionInformation(
                      region: region,
                      minZoom: minZoom,
                      maxZoom: maxZoom,
                    ),
                    const Divider(thickness: 2, height: 8),
                    const OptionsPane(
                      label: 'STORE DIRECTORY',
                      children: [StoreSelector()],
                    ),
                    OptionsPane(
                      label: 'PERFORMANCE FACTORS',
                      children: [
                        NumericalInputRow(
                          label: 'Parallel Threads',
                          suffixText: 'threads',
                          value: (provider) => provider.parallelThreads,
                          min: 1,
                          max: 10,
                          onChanged: (provider, value) =>
                              provider.parallelThreads = value,
                        ),
                        NumericalInputRow(
                          label: 'Rate Limit',
                          suffixText: 'max. tps',
                          value: (provider) => provider.rateLimit,
                          min: 1,
                          max: 50000,
                          maxEligibleTilesPreview: 20,
                          onChanged: (provider, value) =>
                              provider.rateLimit = value,
                        ),
                        NumericalInputRow(
                          label: 'Tile Buffer Length',
                          suffixText: 'max. tiles',
                          value: (provider) => provider.maxBufferLength,
                          min: 0,
                          max: null,
                          onChanged: (provider, value) =>
                              provider.maxBufferLength = value,
                        ),
                      ],
                    ),
                    OptionsPane(
                      label: 'SKIP TILES',
                      children: [
                        Row(
                          children: [
                            const Text('Skip Existing Tiles'),
                            const Spacer(),
                            Switch.adaptive(
                              value: context
                                  .select<ConfigureDownloadProvider, bool>(
                                (provider) => provider.skipExistingTiles,
                              ),
                              onChanged: (val) => context
                                  .read<ConfigureDownloadProvider>()
                                  .skipExistingTiles = val,
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Skip Sea Tiles'),
                            const Spacer(),
                            Switch.adaptive(
                              value: context.select<ConfigureDownloadProvider,
                                  bool>((provider) => provider.skipSeaTiles),
                              onChanged: (val) => context
                                  .read<ConfigureDownloadProvider>()
                                  .skipSeaTiles = val,
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 72),
                  ].interleave(const SizedBox.square(dimension: 16)).toList(),
                ),
              ),
            ),
            Selector<ConfigureDownloadProvider, bool>(
              selector: (context, provider) => provider.isReady,
              builder: (context, isReady, _) => IgnorePointer(
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
      );
}
