import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../configure_download/configure_download.dart';
import '../../region_selection/state/region_selection_provider.dart';

class RecoveryStartButton extends StatelessWidget {
  const RecoveryStartButton({
    super.key,
    required this.moveToDownloadPage,
    required this.result,
  });

  final void Function() moveToDownloadPage;
  final ({bool isFailed, RecoveredRegion region}) result;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          Icons.download,
          color: result.isFailed ? Colors.green : null,
        ),
        onPressed: !result.isFailed
            ? null
            : () async {
                final regionSelectionProvider =
                    Provider.of<RegionSelectionProvider>(context, listen: false)
                      ..region = result.region.toRegion()
                      ..minZoom = result.region.minZoom
                      ..maxZoom = result.region.maxZoom
                      ..setSelectedStore(
                        FMTCStore(result.region.storeName),
                      );

                await Navigator.of(context).push(
                  MaterialPageRoute<String>(
                    builder: (context) => ConfigureDownloadPopup(
                      region: regionSelectionProvider.region!,
                      minZoom: result.region.minZoom,
                      maxZoom: result.region.maxZoom,
                      startTile: result.region.start,
                      endTile: result.region.end,
                    ),
                    fullscreenDialog: true,
                  ),
                );

                moveToDownloadPage();
              },
      );
}
