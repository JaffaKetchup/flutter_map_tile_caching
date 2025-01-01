import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../shared/state/general_provider.dart';

class LoadingBehaviourSelector extends StatelessWidget {
  const LoadingBehaviourSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      Selector<GeneralProvider, BrowseLoadingStrategy>(
        selector: (context, provider) => provider.loadingStrategy,
        builder: (context, loadingStrategy, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                'Preferred Loading Strategy',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton(
                segments: const [
                  ButtonSegment(
                    value: BrowseLoadingStrategy.cacheOnly,
                    icon: Icon(Icons.download_for_offline_outlined),
                    label: Text('Cache Only'),
                  ),
                  ButtonSegment(
                    value: BrowseLoadingStrategy.cacheFirst,
                    icon: Icon(Icons.storage_rounded),
                    label: Text('Cache First'),
                  ),
                  ButtonSegment(
                    value: BrowseLoadingStrategy.onlineFirst,
                    icon: Icon(Icons.public_rounded),
                    label: Text('Online First'),
                  ),
                ],
                selected: {loadingStrategy},
                onSelectionChanged: (value) => context
                    .read<GeneralProvider>()
                    .loadingStrategy = value.single,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
}
