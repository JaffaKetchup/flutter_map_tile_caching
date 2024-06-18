import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/components/url_selector.dart';
import '../../../../../shared/state/general_provider.dart';

class ConfigPanelMap extends StatelessWidget {
  const ConfigPanelMap({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          URLSelector(
            initialValue: context.select<GeneralProvider, String>(
              (provider) => provider.urlTemplate,
            ),
            onSelected: (urlTemplate) =>
                context.read<GeneralProvider>().urlTemplate = urlTemplate,
          ),
          const SizedBox(height: 6),
          Selector<GeneralProvider, bool>(
            selector: (context, provider) => provider.displayDebugOverlay,
            builder: (context, displayDebugOverlay, _) => Row(
              children: [
                const SizedBox(width: 8),
                const Text('Display debug/info tile overlay'),
                const Spacer(),
                Switch.adaptive(
                  value: displayDebugOverlay,
                  onChanged: (value) => context
                      .read<GeneralProvider>()
                      .displayDebugOverlay = value,
                  thumbIcon: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Icon(Icons.layers)
                        : const Icon(Icons.layers_clear),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      );
}
