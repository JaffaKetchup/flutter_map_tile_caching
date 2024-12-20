import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/components/url_selector.dart';
import '../../../../../../../shared/state/general_provider.dart';
import '../../../../layouts/bottom_sheet/components/scrollable_provider.dart';
import 'components/loading_behaviour_selector.dart';

class MapConfigurator extends StatefulWidget {
  const MapConfigurator({super.key});

  @override
  State<MapConfigurator> createState() => _MapConfiguratorState();
}

class _MapConfiguratorState extends State<MapConfigurator> {
  double? _previousBottomSheetOuterHeight;
  double? _previousBottomSheetInnerHeight;

  @override
  Widget build(BuildContext context) {
    final bottomSheetOuterController =
        BottomSheetScrollableProvider.maybeOuterScrollControllerOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UrlSelector(
          initialValue: context.select<GeneralProvider, String>(
            (provider) => provider.urlTemplate,
          ),
          onSelected: (urlTemplate) =>
              context.read<GeneralProvider>().urlTemplate = urlTemplate,
          onFocus: bottomSheetOuterController != null
              ? () {
                  final innerController =
                      BottomSheetScrollableProvider.innerScrollControllerOf(
                    context,
                  );

                  _previousBottomSheetOuterHeight =
                      bottomSheetOuterController.size;
                  _previousBottomSheetInnerHeight = innerController.offset;

                  bottomSheetOuterController.animateTo(
                    1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                  innerController.animateTo(
                    1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
          onUnfocus: bottomSheetOuterController != null
              ? () {
                  final innerController =
                      BottomSheetScrollableProvider.innerScrollControllerOf(
                    context,
                  );

                  bottomSheetOuterController.animateTo(
                    _previousBottomSheetOuterHeight ?? 0.3,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                  innerController.animateTo(
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
                onChanged: (value) =>
                    context.read<GeneralProvider>().displayDebugOverlay = value,
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
}
