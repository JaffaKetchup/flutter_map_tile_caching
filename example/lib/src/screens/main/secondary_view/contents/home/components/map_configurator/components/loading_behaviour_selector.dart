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
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    label: Text('Cache'),
                  ),
                  ButtonSegment(
                    value: BrowseLoadingStrategy.onlineFirst,
                    icon: Icon(Icons.public_rounded),
                    label: Text('Network'),
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
            /*Selector<GeneralProvider, bool>(
              selector: (context, provider) =>
                  provider.behaviourUpdateFromNetwork,
              builder: (context, behaviourUpdateFromNetwork, _) => Row(
                children: [
                  const SizedBox(width: 8),
                  const Text('Update cache when network used'),
                  const Spacer(),
                  Switch.adaptive(
                    value: cacheBehavior != null && behaviourUpdateFromNetwork,
                    onChanged: cacheBehavior == null
                        ? null
                        : (value) => context
                            .read<GeneralProvider>()
                            .behaviourUpdateFromNetwork = value,
                    thumbIcon: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? const Icon(Icons.edit)
                          : const Icon(Icons.edit_off),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),*/
          ],
        ),
      );
}
