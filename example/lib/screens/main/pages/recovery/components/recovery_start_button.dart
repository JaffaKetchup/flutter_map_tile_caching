import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';
import '../../../../download_region/download_region.dart';

class RecoveryStartButton extends StatelessWidget {
  const RecoveryStartButton({
    Key? key,
    required this.moveToDownloadPage,
    required this.region,
  }) : super(key: key);

  final void Function() moveToDownloadPage;
  final RecoveredRegion region;

  @override
  Widget build(BuildContext context) => FutureBuilder<RecoveredRegion?>(
        future: FMTC.instance.rootDirectory.recovery.getFailedRegion(region.id),
        builder: (context, isFailed) => FutureBuilder<int>(
          future: FMTC
              .instance('')
              .download
              .check(region.toDownloadable(TileLayer())),
          builder: (context, tiles) => tiles.hasData
              ? IconButton(
                  icon: Icon(
                    Icons.download,
                    color: isFailed.data != null ? Colors.green : null,
                  ),
                  onPressed: isFailed.data == null
                      ? null
                      : () async {
                          final DownloadProvider downloadProvider =
                              Provider.of<DownloadProvider>(
                            context,
                            listen: false,
                          )
                                ..region = region
                                    .toDownloadable(TileLayer())
                                    .originalRegion
                                ..minZoom = region.minZoom
                                ..maxZoom = region.maxZoom
                                ..preventRedownload = region.preventRedownload
                                ..seaTileRemoval = region.seaTileRemoval
                                ..setSelectedStore(
                                  FMTC.instance(region.storeName),
                                )
                                ..regionTiles = tiles.data;

                          await Navigator.of(context).push(
                            MaterialPageRoute<String>(
                              builder: (BuildContext context) =>
                                  DownloadRegionPopup(
                                region: downloadProvider.region!,
                              ),
                              fullscreenDialog: true,
                            ),
                          );

                          moveToDownloadPage();
                        },
                )
              : const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                ),
        ),
      );
}
