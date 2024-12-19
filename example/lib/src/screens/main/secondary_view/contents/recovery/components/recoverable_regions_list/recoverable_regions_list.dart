import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/download_configuration_provider.dart';
import '../../../../../../../shared/state/download_provider.dart';
import '../../../../../../../shared/state/general_provider.dart';
import '../../../../../../../shared/state/recoverable_regions_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';
import '../../../../../../../shared/state/selected_tab_state.dart';
import '../../../region_selection/components/shared/to_config_method.dart';
import 'components/no_regions.dart';

class RecoverableRegionsList extends StatefulWidget {
  const RecoverableRegionsList({super.key});

  @override
  State<RecoverableRegionsList> createState() => _RecoverableRegionsListState();
}

class _RecoverableRegionsListState extends State<RecoverableRegionsList> {
  bool _preventCameraReturnFlag = false;
  (LatLng, double)? _initialMapPosition;
  AnimatedMapController? _animatedMapController;
  StreamSubscription<MapEvent>? _mapEventStreamSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _animatedMapController ??=
        context.read<GeneralProvider>().animatedMapController;

    _mapEventStreamSub ??=
        _animatedMapController!.mapController.mapEventStream.listen((evt) {
      if (AnimationId.fromMapEvent(evt) != null) return;
      _preventCameraReturnFlag = true;
      _mapEventStreamSub!.cancel();
    });

    _initialMapPosition ??= (
      _animatedMapController!.mapController.camera.center,
      _animatedMapController!.mapController.camera.zoom,
    );

    final failedRegions =
        context.read<RecoverableRegionsProvider>().failedRegions.keys;
    if (failedRegions.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(
      failedRegions.first.region.regions.first
          .toOutline()
          .toList(growable: false),
    );
    for (final region in failedRegions
        .map((failedRegion) => failedRegion.region.regions)
        .flattened) {
      bounds.extendBounds(
        LatLngBounds.fromPoints(region.toOutline().toList(growable: false)),
      );
    }
    _animatedMapController!.animatedFitCamera(
      cameraFit: CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(16) +
            MediaQueryData.fromView(View.of(context)).padding +
            const EdgeInsets.only(bottom: 18),
      ),
    );
  }

  @override
  void dispose() {
    if (!_preventCameraReturnFlag) {
      _animatedMapController!.animateTo(
        dest: _initialMapPosition!.$1,
        zoom: _initialMapPosition!.$2,
      );
    }
    _mapEventStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Selector<RecoverableRegionsProvider,
          UnmodifiableMapView<RecoveredRegion<MultiRegion>, HSLColor>>(
        selector: (context, provider) => provider.failedRegions,
        builder: (context, failedRegions, _) {
          if (failedRegions.isEmpty) return const NoRegions();

          return SliverList.builder(
            itemCount: failedRegions.length,
            itemBuilder: (context, index) {
              final failedRegion = failedRegions.keys.elementAt(index);
              final color = failedRegions.values.elementAt(index);

              return ListTile(
                leading: Icon(Icons.shape_line, color: color.toColor()),
                title: Text("To '${failedRegion.storeName}'"),
                subtitle: Text(
                  '${failedRegion.time.toLocal()}\n'
                  '${failedRegion.end - failedRegion.start + 1} remaining tiles',
                ),
                isThreeLine: true,
                trailing: IntrinsicHeight(
                  child: Selector<DownloadConfigurationProvider, int?>(
                    selector: (context, provider) => provider.fromRecovery,
                    builder: (context, fromRecovery, _) {
                      if (fromRecovery == failedRegion.id) {
                        return SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: () {
                              _preventCameraReturnFlag = true;
                              selectedTabState.value = 1;
                              prepareDownloadConfigView(context);
                            },
                            icon: const Icon(Icons.tune),
                            label: const Text('View In Configurator'),
                          ),
                        );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () =>
                                FMTCRoot.recovery.cancel(failedRegion.id),
                            icon: const Icon(Icons.delete_forever),
                            tooltip: 'Delete',
                          ),
                          SizedBox(
                            height: double.infinity,
                            child: Selector<DownloadingProvider, bool>(
                              selector: (context, provider) =>
                                  provider.storeName != null,
                              builder: (context, isDownloading, _) =>
                                  Selector<RegionSelectionProvider, bool>(
                                selector: (context, provider) =>
                                    provider.constructedRegions.isNotEmpty,
                                builder: (context, isConstructingRegion, _) {
                                  final cannotResume =
                                      isConstructingRegion || isDownloading;
                                  final button = FilledButton.tonalIcon(
                                    onPressed: cannotResume
                                        ? null
                                        : () => _resumeDownload(failedRegion),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Resume'),
                                  );
                                  if (!cannotResume) return button;
                                  return Tooltip(
                                    message: 'Cannot start another download',
                                    child: button,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      );

  void _resumeDownload(RecoveredRegion<MultiRegion> failedRegion) {
    final regionSelectionProvider = context.read<RegionSelectionProvider>()
      ..clearCoordinates();
    failedRegion.region.regions
        .forEach(regionSelectionProvider.addConstructedRegion);
    context.read<DownloadConfigurationProvider>()
      ..selectedStoreName = failedRegion.storeName
      ..minZoom = failedRegion.minZoom
      ..maxZoom = failedRegion.maxZoom
      ..startTile = failedRegion.start
      ..endTile = failedRegion.end
      ..fromRecovery = failedRegion.id;

    _preventCameraReturnFlag = true;
    selectedTabState.value = 1;
    prepareDownloadConfigView(context);
  }
}
