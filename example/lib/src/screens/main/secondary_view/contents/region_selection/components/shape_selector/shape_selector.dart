import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/region_selection_provider.dart';
import '../shared/to_config_method.dart';

part 'components/animated_visibility_icon_button.dart';

class ShapeSelector extends StatefulWidget {
  const ShapeSelector({super.key});

  @override
  State<ShapeSelector> createState() => _ShapeSelectorState();
}

class _ShapeSelectorState extends State<ShapeSelector> {
  static const _regionShapes = {
    RegionType.rectangle: (
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
  Widget build(BuildContext context) {
    final provider = context.watch<RegionSelectionProvider>();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton(
              segments: _regionShapes.entries
                  .map(
                    (e) => ButtonSegment(
                      value: e.key,
                      icon: Icon(
                        provider.currentRegionType == e.key
                            ? e.value.selectedIcon
                            : e.value.unselectedIcon,
                      ),
                      tooltip: e.value.label,
                    ),
                  )
                  .toList(),
              selected: {provider.currentRegionType},
              showSelectedIcon: false,
              onSelectionChanged: (type) => provider
                ..currentRegionType = type.single
                ..clearCoordinates(),
              style:
                  const ButtonStyle(visualDensity: VisualDensity.comfortable),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,
            firstChild: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: provider.lineRadius,
                      onChanged: (v) => provider.lineRadius = v,
                      min: 100,
                      max: 5000,
                    ),
                  ),
                  Text(
                    '${provider.lineRadius.round().toString().padLeft(4, '0')}'
                    'm',
                  ),
                  const VerticalDivider(),
                  IconButton.outlined(
                    onPressed: () async {
                      final provider = context.read<RegionSelectionProvider>();

                      final pickerResult = Platform.isAndroid || Platform.isIOS
                          ? await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                            )
                          : await FilePicker.platform.pickFiles(
                              dialogTitle: 'Import GPX',
                              type: FileType.custom,
                              allowedExtensions: ['gpx'],
                              allowMultiple: true,
                            );

                      if (pickerResult == null) return;

                      final gpxReader = GpxReader();
                      for (final path
                          in pickerResult.files.map((e) => e.path)) {
                        provider.addCoordinates(
                          gpxReader
                              .fromString(await File(path!).readAsString())
                              .trks
                              .map(
                                (e) => e.trksegs.map(
                                  (e) => e.trkpts
                                      .map((e) => LatLng(e.lat!, e.lon!)),
                                ),
                              )
                              .expand((e) => e)
                              .expand((e) => e),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_open_rounded),
                    tooltip: 'Import from GPX',
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(
              width: double.infinity,
            ),
            crossFadeState: provider.currentRegionType == RegionType.line
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AutoSizeText(
                      'Tap to add point',
                      maxLines: 1,
                      minFontSize: 0,
                    ),
                    AutoSizeText(
                      provider.regionSelectionMethod ==
                              RegionSelectionMethod.useMapCenter
                          ? 'at map center'
                          : 'at tap position',
                      maxLines: 1,
                      minFontSize: 0,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FittedBox(
                child: Row(
                  children: [
                    const SizedBox.shrink(),
                    IconButton.outlined(
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
                    ),
                    _AnimatedVisibilityIconButton.outlined(
                      onPressed:
                          provider.currentConstructingCoordinates.length < 2
                              ? null
                              : _removeLastCoordinate,
                      icon: const Icon(Icons.backspace),
                      tooltip: 'Remove last coordinate (alt. interact)',
                      isVisible:
                          provider.currentRegionType == RegionType.line ||
                              provider.currentRegionType ==
                                  RegionType.customPolygon,
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: provider.currentConstructingCoordinates.isEmpty
                          ? null
                          : _clearCoordinates,
                      icon: const Icon(Icons.delete),
                    ),
                    _AnimatedVisibilityIconButton.filledTonal(
                      onPressed:
                          provider.currentConstructingCoordinates.length < 2
                              ? null
                              : _addSubRegion,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add sub-region',
                      isVisible: provider.currentRegionType == RegionType.line,
                    ),
                    _AnimatedVisibilityIconButton.filled(
                      onPressed:
                          provider.currentConstructingCoordinates.length < 2
                              ? null
                              : _completeRegion,
                      icon: const Icon(Icons.done),
                      tooltip: 'Complete region',
                      isVisible:
                          provider.currentRegionType == RegionType.line &&
                              provider.constructedRegions.isEmpty,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _completeRegion() {
    _addSubRegion();
    prepareDownloadConfigView(context);
  }

  void _addSubRegion() {
    final provider = context.read<RegionSelectionProvider>();
    provider.addConstructedRegion(
      LineRegion(provider.currentConstructingCoordinates, provider.lineRadius),
    );
  }

  void _removeLastCoordinate() {
    context.read<RegionSelectionProvider>().removeLastCoordinate();
  }

  void _clearCoordinates() {
    context.read<RegionSelectionProvider>().clearCoordinates();
  }
}
