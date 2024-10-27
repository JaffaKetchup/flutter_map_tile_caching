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
                  'it to the list of (sub-)regions to download.',
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 82),
                const Icon(Icons.view_cozy_outlined, size: 64),
                const SizedBox(height: 12),
                Text(
                  'No sub-regions constructed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      );
}
