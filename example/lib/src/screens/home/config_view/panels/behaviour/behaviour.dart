import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';

class ConfigPanelBehaviour extends StatelessWidget {
  const ConfigPanelBehaviour({
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      Selector<GeneralProvider, CacheBehavior>(
        selector: (context, provider) => provider.cacheBehavior,
        builder: (context, cacheBehavior, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton(
                segments: const [
                  ButtonSegment(
                    value: CacheBehavior.cacheOnly,
                    icon: Icon(Icons.download_for_offline_outlined),
                    label: Text('Cache Only'),
                  ),
                  ButtonSegment(
                    value: CacheBehavior.cacheFirst,
                    icon: Icon(Icons.storage_rounded),
                    label: Text('Cache'),
                  ),
                  ButtonSegment(
                    value: CacheBehavior.onlineFirst,
                    icon: Icon(Icons.public_rounded),
                    label: Text('Network'),
                  ),
                ],
                selected: {cacheBehavior},
                onSelectionChanged: (value) => context
                    .read<GeneralProvider>()
                    .cacheBehavior = value.single,
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
