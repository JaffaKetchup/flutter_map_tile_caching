import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/region_selection_method.dart';
import '../../../../../shared/misc/region_type.dart';
import '../../../../../shared/state/download_provider.dart';
import 'custom_slider_track_shape.dart';
import 'min_max_zoom_controller_popup.dart';

class SidePanel extends StatelessWidget {
  SidePanel({
    super.key,
    required this.constraints,
  }) : layoutDirection =
            constraints.maxWidth > 800 ? Axis.vertical : Axis.horizontal;

  final BoxConstraints constraints;
  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => PositionedDirectional(
        top: layoutDirection == Axis.vertical ? 12 : null,
        bottom: 12,
        start: layoutDirection == Axis.vertical ? 24 : 12,
        end: layoutDirection == Axis.vertical ? null : 12,
        child: Center(
          child: layoutDirection == Axis.vertical
              ? IntrinsicHeight(
                  child: PaneGroup(layoutDirection: layoutDirection),
                )
              : FittedBox(
                  child: IntrinsicWidth(
                    child: PaneGroup(layoutDirection: layoutDirection),
                  ),
                ),
        ),
      );
}

class PaneGroup extends StatelessWidget {
  const PaneGroup({
    super.key,
    required this.layoutDirection,
  });

  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => Flex(
        direction:
            layoutDirection == Axis.vertical ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        verticalDirection: layoutDirection == Axis.horizontal
            ? VerticalDirection.up
            : VerticalDirection.down,
        children: [
          Flex(
            direction: layoutDirection,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(1028),
                ),
                padding: const EdgeInsets.all(12),
                child: Flex(
                  direction: layoutDirection,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    RegionShapeButton(
                      type: RegionType.square,
                      selectedIcon: Icon(Icons.square),
                      unselectedIcon: Icon(Icons.square_outlined),
                      tooltip: 'Rectangle',
                    ),
                    SizedBox.square(dimension: 12),
                    RegionShapeButton(
                      type: RegionType.circle,
                      selectedIcon: Icon(Icons.circle),
                      unselectedIcon: Icon(Icons.circle_outlined),
                      tooltip: 'Circle',
                    ),
                    SizedBox.square(dimension: 12),
                    RegionShapeButton(
                      type: RegionType.line,
                      selectedIcon: Icon(Icons.polyline),
                      unselectedIcon: Icon(Icons.polyline_outlined),
                      tooltip: 'Line',
                    ),
                    SizedBox.square(dimension: 12),
                    RegionShapeButton(
                      type: RegionType.customPolygon,
                      selectedIcon: Icon(Icons.pentagon),
                      unselectedIcon: Icon(Icons.pentagon_outlined),
                      tooltip: 'Custom Polygon',
                    ),
                  ],
                ),
              ),
              const SizedBox.square(dimension: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(1028),
                ),
                padding: const EdgeInsets.all(12),
                child: Consumer<DownloaderProvider>(
                  builder: (context, provider, _) => IconButton(
                    onPressed: () => provider.regionSelectionMethod =
                        provider.regionSelectionMethod ==
                                RegionSelectionMethod.useMapCenter
                            ? RegionSelectionMethod.usePointer
                            : RegionSelectionMethod.useMapCenter,
                    icon: Icon(
                      provider.regionSelectionMethod ==
                              RegionSelectionMethod.useMapCenter
                          ? Icons.filter_center_focus
                          : Icons.ads_click,
                    ),
                    tooltip: provider.regionSelectionMethod ==
                            RegionSelectionMethod.useMapCenter
                        ? 'Use Map Center'
                        : 'Use Pointer',
                  ),
                ),
              ),
              const SizedBox.square(dimension: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(1028),
                ),
                padding: const EdgeInsets.all(12),
                child: Consumer<DownloaderProvider>(
                  builder: (context, provider, _) => Flex(
                    direction: layoutDirection,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => provider
                          ..clearCoordinates()
                          ..region = null,
                        icon: const Icon(Icons.delete_forever),
                        tooltip: 'Remove All Points',
                      ),
                      const SizedBox.square(dimension: 12),
                      IconButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => const MinMaxZoomControllerPopup(),
                        ),
                        icon: const Icon(Icons.zoom_in),
                        tooltip: 'Adjust Zoom Levels',
                      ),
                      const SizedBox.square(dimension: 12),
                      IconButton.filled(
                        onPressed: provider.region != null ? () {} : null,
                        icon: const Icon(Icons.done),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox.square(dimension: 12),
          Consumer<DownloaderProvider>(
            builder: (context, provider, _) => IgnorePointer(
              ignoring: provider.regionType != RegionType.line,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                opacity: provider.regionType == RegionType.line ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(1028),
                  ),
                  padding: layoutDirection == Axis.vertical
                      ? const EdgeInsets.symmetric(vertical: 24, horizontal: 12)
                      : const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                  child: Flex(
                    direction: layoutDirection,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (layoutDirection == Axis.vertical) ...[
                        Text('${provider.lineRadius.round()}m'),
                        const Text('radius'),
                      ],
                      if (layoutDirection == Axis.horizontal)
                        Text('${provider.lineRadius.round()}m radius'),
                      Expanded(
                        child: Padding(
                          padding: layoutDirection == Axis.vertical
                              ? const EdgeInsets.only(bottom: 12, top: 28)
                              : const EdgeInsets.only(left: 28, right: 12),
                          child: RotatedBox(
                            quarterTurns:
                                layoutDirection == Axis.vertical ? 3 : 0,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackShape: CustomSliderTrackShape(),
                              ),
                              child: Slider(
                                value: provider.lineRadius,
                                onChanged: (v) => provider.lineRadius = v,
                                min: 100,
                                max: 5000,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class RegionShapeButton extends StatelessWidget {
  const RegionShapeButton({
    super.key,
    required this.type,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.tooltip,
  });

  final RegionType type;
  final Icon selectedIcon;
  final Icon unselectedIcon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Consumer<DownloaderProvider>(
        builder: (context, provider, _) => IconButton(
          isSelected: provider.regionType == type,
          onPressed: () => provider
            ..regionType = type
            ..clearCoordinates(),
          icon: unselectedIcon,
          selectedIcon: selectedIcon,
          tooltip: tooltip,
        ),
      );
}
