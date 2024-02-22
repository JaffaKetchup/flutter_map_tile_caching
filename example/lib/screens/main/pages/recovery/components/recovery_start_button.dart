import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class RecoveryStartButton extends StatelessWidget {
  const RecoveryStartButton({
    super.key,
    required this.moveToDownloadPage,
    required this.result,
  });

  final void Function() moveToDownloadPage;
  final ({bool isFailed, RecoveredRegion region}) result;

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
        future: const FMTCStore('')
            .download
            .check(result.region.toDownloadable(TileLayer())),
        builder: (context, tiles) => tiles.hasData
            ? IconButton(
                icon: Icon(
                  Icons.download,
                  color: result.isFailed ? Colors.green : null,
                ),
                onPressed: !result.isFailed
                    ? null
                    : () async {
                        //TODO: Implement
                        /* final DownloaderProvider downloadProvider =
                        Provider.of<DownloaderProvider>(
                      context,
                      listen: false,
                    )
                          ..region = region.toRegion(
                            rectangle: (r) => r,
                            circle: (c) => c,
                            line: (l) => l,
                          )
                          ..minZoom = region.minZoom
                          ..maxZoom = region.maxZoom
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
  
                    moveToDownloadPage();*/
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
      );
}
