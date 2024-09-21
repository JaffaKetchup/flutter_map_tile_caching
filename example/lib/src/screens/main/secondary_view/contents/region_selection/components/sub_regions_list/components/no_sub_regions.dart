import 'package:flutter/material.dart';

class NoSubRegions extends StatelessWidget {
  const NoSubRegions({super.key});

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Bulk downloading',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'To bulk download a map, first create a region. Select the '
                  'shape above, and tap on the map to add points. Once a '
                  'region has been finished, download it immediately, or add '
                  'it to the list of sub-regions to download.',
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 82),
                const Icon(Icons.view_cozy_outlined, size: 64),
                const SizedBox(height: 12),
                Text(
                  'No sub-regions selected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'FMTC supports `MultiRegion`s formed of multiple other '
                  'regions.\nYou can select an area to download and use the '
                  'panel below to download it, or add it to the list of '
                  'sub-regions using the button above.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}
