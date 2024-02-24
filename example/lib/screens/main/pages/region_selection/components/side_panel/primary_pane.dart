part of 'parent.dart';

class _PrimaryPane extends StatelessWidget {
  const _PrimaryPane({
    required this.constraints,
    required this.layoutDirection,
    required this.pushToConfigureDownload,
  });

  final BoxConstraints constraints;
  final void Function() pushToConfigureDownload;

  final Axis layoutDirection;

  static const regionShapes = {
    RegionType.square: (
      selectedIcon: Icons.square,
      unselectedIcon: Icons.square_outlined,
      label: 'Rectangle',
    ),
    RegionType.circle: (
      selectedIcon: Icons.circle,
      unselectedIcon: Icons.circle_outlined,
      label: 'Circle',
    ),
    RegionType.line: (
      selectedIcon: Icons.polyline,
      unselectedIcon: Icons.polyline_outlined,
      label: 'Polyline + Radius',
    ),
    RegionType.customPolygon: (
      selectedIcon: Icons.pentagon,
      unselectedIcon: Icons.pentagon_outlined,
      label: 'Polygon',
    ),
  };

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
                child: (layoutDirection == Axis.vertical
                            ? constraints.maxHeight
                            : constraints.maxWidth) <
                        500
                    ? Consumer<RegionSelectionProvider>(
                        builder: (context, provider, _) => IconButton(
                          icon: Icon(
                            regionShapes[provider.regionType]!.selectedIcon,
                          ),
                          onPressed: () => provider
                            ..regionType = regionShapes.keys.elementAt(
                              (regionShapes.keys
                                          .toList()
                                          .indexOf(provider.regionType) +
                                      1) %
                                  4,
                            )
                            ..clearCoordinates(),
                          tooltip: 'Switch Region Shape',
                        ),
                      )
                    : Flex(
                        direction: layoutDirection,
                        mainAxisSize: MainAxisSize.min,
                        children: regionShapes.entries
                            .map<Widget>(
                              (e) => _RegionShapeButton(
                                type: e.key,
                                selectedIcon: Icon(e.value.selectedIcon),
                                unselectedIcon: Icon(e.value.unselectedIcon),
                                tooltip: e.value.label,
                              ),
                            )
                            .interleave(const SizedBox.square(dimension: 12))
                            .toList(),
                      ),
              ),
              const SizedBox.square(dimension: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(1028),
                ),
                padding: const EdgeInsets.all(12),
                child: Flex(
                  direction: layoutDirection,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Selector<RegionSelectionProvider, RegionSelectionMethod>(
                      selector: (context, provider) =>
                          provider.regionSelectionMethod,
                      builder: (context, method, _) => IconButton(
                        icon: Icon(
                          method == RegionSelectionMethod.useMapCenter
                              ? Icons.filter_center_focus
                              : Icons.ads_click,
                        ),
                        onPressed: () => context
                                .read<RegionSelectionProvider>()
                                .regionSelectionMethod =
                            method == RegionSelectionMethod.useMapCenter
                                ? RegionSelectionMethod.usePointer
                                : RegionSelectionMethod.useMapCenter,
                        tooltip: 'Switch Selection Method',
                      ),
                    ),
                    const SizedBox.square(dimension: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () => context
                          .read<RegionSelectionProvider>()
                          .clearCoordinates(),
                      tooltip: 'Remove All Points',
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
                child: Consumer<RegionSelectionProvider>(
                  builder: (context, provider, _) => Flex(
                    direction: layoutDirection,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.openAdjustZoomLevelsSlider)
                        IconButton.outlined(
                          icon: Icon(
                            layoutDirection == Axis.vertical
                                ? Icons.arrow_left
                                : Icons.arrow_drop_down,
                          ),
                          onPressed: () =>
                              provider.openAdjustZoomLevelsSlider = false,
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          onPressed: () =>
                              provider.openAdjustZoomLevelsSlider = true,
                        ),
                      const SizedBox.square(dimension: 12),
                      IconButton.filled(
                        icon: const Icon(Icons.done),
                        onPressed: provider.region != null
                            ? pushToConfigureDownload
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox.square(dimension: 12),
          _AdditionalPane(
            constraints: constraints,
            layoutDirection: layoutDirection,
          ),
        ],
      );
}
