import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/misc/exts/interleave.dart';
import '../../shared/state/region_selection_provider.dart';
import 'components/numerical_input_row.dart';
import 'components/options_pane.dart';
import 'components/region_information.dart';
import 'components/start_download_button.dart';
import 'components/store_selector.dart';
import 'state/configure_download_provider.dart';

class ConfigureDownloadPopup extends StatefulWidget {
  const ConfigureDownloadPopup({super.key});

  static const String route = '/download/configure';

  @override
  State<ConfigureDownloadPopup> createState() => _ConfigureDownloadPopupState();
}

class _ConfigureDownloadPopupState extends State<ConfigureDownloadPopup> {
  DownloadableRegion? region;
  int? maxTiles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<RegionSelectionProvider>();
    const FMTCStore('')
        .download
        .check(
          region ??= provider.region!.toDownloadable(
            minZoom: provider.minZoom,
            maxZoom: provider.maxZoom,
            start: provider.startTile,
            end: provider.endTile,
            options: TileLayer(),
          ),
        )
        .then((v) => setState(() => maxTiles = v));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Configure Bulk Download')),
        floatingActionButton: StartDownloadButton(
          region: region!,
          maxTiles: maxTiles,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox.shrink(),
                RegionInformation(
                  region: region!,
                  maxTiles: maxTiles,
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
                      max: 300,
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
                          value:
                              context.select<ConfigureDownloadProvider, bool>(
                            (provider) => provider.skipExistingTiles,
                          ),
                          onChanged: (val) => context
                              .read<ConfigureDownloadProvider>()
                              .skipExistingTiles = val,
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Skip Sea Tiles'),
                        const Spacer(),
                        Switch.adaptive(
                          value:
                              context.select<ConfigureDownloadProvider, bool>(
                            (provider) => provider.skipSeaTiles,
                          ),
                          onChanged: (val) => context
                              .read<ConfigureDownloadProvider>()
                              .skipSeaTiles = val,
                          activeColor: Theme.of(context).colorScheme.primary,
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
      );
}
