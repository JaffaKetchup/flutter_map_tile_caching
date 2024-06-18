import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';

class ConfigPanelBehaviour extends StatelessWidget {
  const ConfigPanelBehaviour({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Selector<GeneralProvider, bool?>(
        selector: (context, provider) => provider.behaviourPrimary,
        builder: (context, behaviourPrimary, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton(
                segments: const [
                  ButtonSegment(
                    value: null,
                    icon: Icon(Icons.download_for_offline_outlined),
                    label: Text('Cache Only'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.storage_rounded),
                    label: Text('Cache'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.public_rounded),
                    label: Text('Network'),
                  ),
                ],
                selected: {behaviourPrimary},
                onSelectionChanged: (value) => context
                    .read<GeneralProvider>()
                    .behaviourPrimary = value.single,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Selector<GeneralProvider, bool>(
              selector: (context, provider) =>
                  provider.behaviourUpdateFromNetwork,
              builder: (context, behaviourUpdateFromNetwork, _) => Row(
                children: [
                  const SizedBox(width: 8),
                  const Text('Update cache when network used'),
                  const Spacer(),
                  Switch.adaptive(
                    value:
                        behaviourPrimary != null && behaviourUpdateFromNetwork,
                    onChanged: behaviourPrimary == null
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
            ),
          ],
        ),
      );
}
