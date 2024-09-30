import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../shared/misc/store_metadata_keys.dart';
import '../../download/download.dart';
import '../../../../shared/state/download_configuration_provider.dart';

class StartDownloadButton extends StatelessWidget {
  const StartDownloadButton({
    super.key,
    required this.region,
    required this.maxTiles,
  });

  final DownloadableRegion region;
  final int? maxTiles;

  @override
  Widget build(BuildContext context) =>
      Selector<DownloadConfigurationProvider, FMTCStore?>(
        selector: (context, provider) => provider.selectedStore,
        builder: (context, selectedStore, child) {
          final enabled = selectedStore != null && maxTiles != null;

          return IgnorePointer(
            ignoring: !enabled,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: () async {
                final configureDownloadProvider =
                    context.read<DownloadConfigurationProvider>();

                if (!await configureDownloadProvider
                        .selectedStore!.manage.ready &&
                    context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selected store no longer exists'),
                    ),
                  );
                  return;
                }

                final urlTemplate = (await configureDownloadProvider
                    .selectedStore!
                    .metadata
                    .read)[StoreMetadataKeys.urlTemplate.key]!;

                if (!context.mounted) return;

                unawaited(
                  Navigator.of(context).popAndPushNamed(
                    DownloadPopup.route,
                    arguments: (
                      downloadProgress: configureDownloadProvider
                          .selectedStore!.download
                          .startForeground(
                        region: region.originalRegion.toDownloadable(
                          minZoom: region.minZoom,
                          maxZoom: region.maxZoom,
                          start: region.start,
                          end: region.end,
                          options: TileLayer(
                            urlTemplate: urlTemplate,
                            userAgentPackageName: 'dev.jaffaketchup.fmtc.demo',
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
                      ),
                      maxTiles: maxTiles!
                    ),
                  ),
                );
              },
              label: const Text('Start Download'),
              icon: const Icon(Icons.save),
            ),
          ],
        ),
      );
}
