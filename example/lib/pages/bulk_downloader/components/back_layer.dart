import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../bulk_downloader.dart';
import 'region_constraints.dart';
import 'map.dart';

class BackLayer extends StatelessWidget {
  const BackLayer({
    Key? key,
    required this.controller,
    required this.mcm,
    required this.mapSource,
    required this.animationDuration,
    required this.region,
    required this.selectedRegionMode,
  }) : super(key: key);

  final MapController controller;
  final MapCachingManager? mcm;
  final String? mapSource;
  final Duration animationDuration;
  final RegionConstraints region;
  final RegionMode selectedRegionMode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          MapView(
            controller: controller,
            mcm: mcm!,
            source: mapSource!,
          ),
          IgnorePointer(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  AnimatedPositioned(
                    duration: animationDuration,
                    top: region.top,
                    left: region.left,
                    child: AnimatedContainer(
                      height: region.height,
                      width: region.width,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: selectedRegionMode == RegionMode.circle
                            ? BorderRadius.circular(region.width / 2)
                            : null,
                      ),
                      duration: animationDuration,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: Backdrop.of(context).isBackLayerRevealed,
              child: AnimatedContainer(
                duration: animationDuration,
                color: Backdrop.of(context).isBackLayerConcealed
                    ? Colors.black.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
