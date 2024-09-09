import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/components/url_selector.dart';
import '../../../../../../../shared/state/general_provider.dart';
import '../../../../layouts/bottom_sheet/components/scrollable_provider.dart';
import 'components/loading_behaviour_selector.dart';

class MapConfigurator extends StatefulWidget {
  const MapConfigurator({
    super.key,
    this.bottomSheetOuterController,
  });

  final DraggableScrollableController? bottomSheetOuterController;

  @override
  State<MapConfigurator> createState() => _MapConfiguratorState();
}

class _MapConfiguratorState extends State<MapConfigurator> {
  double? _previousBottomSheetOuterHeight;
  double? _previousBottomSheetInnerHeight;

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
            onFocus: widget.bottomSheetOuterController != null
                ? () {
                    _previousBottomSheetOuterHeight =
                        widget.bottomSheetOuterController!.size;
                    _previousBottomSheetInnerHeight =
                        BottomSheetScrollableProvider.innerScrollControllerOf(
                      context,
                    ).offset;

                    widget.bottomSheetOuterController!.animateTo(
                      1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                    BottomSheetScrollableProvider.innerScrollControllerOf(
                      context,
                    ).animateTo(
                      1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            onUnfocus: widget.bottomSheetOuterController != null
                ? () {
                    widget.bottomSheetOuterController!.animateTo(
                      _previousBottomSheetOuterHeight ?? 0.3,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                    BottomSheetScrollableProvider.innerScrollControllerOf(
                      context,
                    ).animateTo(
                      _previousBottomSheetInnerHeight ?? 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          const SizedBox(height: 12),
          const LoadingBehaviourSelector(),
          const SizedBox(height: 6),
          Selector<GeneralProvider, bool>(
            selector: (context, provider) => provider.displayDebugOverlay,
            builder: (context, displayDebugOverlay, _) => Row(
              children: [
                const SizedBox(width: 8),
                const Expanded(child: Text('Display debug/info tile overlay')),
                const SizedBox(width: 12),
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
          Selector<GeneralProvider, bool>(
            selector: (context, provider) => provider.fakeNetworkDisconnect,
            builder: (context, fakeNetworkDisconnect, _) => Row(
              children: [
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Fake network disconnect (when FMTC in use)'),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: fakeNetworkDisconnect,
                  onChanged: (value) => context
                      .read<GeneralProvider>()
                      .fakeNetworkDisconnect = value,
                  thumbIcon: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Icon(Icons.cloud_off)
                        : const Icon(Icons.cloud),
                  ),
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.orange
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      );
}
