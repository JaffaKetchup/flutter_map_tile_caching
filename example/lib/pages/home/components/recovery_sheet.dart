import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../state/bulk_download_provider.dart';
import '../../../state/general_provider.dart';

void showRecoverySheet({
  required BuildContext context,
  required List<String> names,
  required List<RecoveredRegion?> allRecoverable,
  required List<RecoveredRegion?> whichRecoverable,
  required Directory cacheDir,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: whichRecoverable.length + 1,
        itemBuilder: (context, i) {
          if (i == whichRecoverable.length) {
            return Column(
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.download_done),
                      SizedBox(width: 20),
                      Text(
                        'All other downloads completed successfully',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final RecoveredRegion rec = whichRecoverable[i]!;
          final String name = names[allRecoverable.indexOf(rec)];

          return ListTile(
            title: Text(name),
            subtitle: Text(
              rec.type.name[0].toUpperCase() + rec.type.name.substring(1),
            ),
            onTap: () async {
              final BulkDownloadProvider bdp =
                  context.read<BulkDownloadProvider>();

              final RecoveredRegion region = (await StorageCachingTileProvider(
                      parentDirectory: cacheDir, _storeName: name)
                  .recoverDownload())!;

              final String mapSource = context
                      .read<GeneralProvider>()
                      .persistent!
                      .getString('$name: sourceURL') ??
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

              final DownloadableRegion downloadableRegion = region
                  .toDownloadable(TileLayerOptions(urlTemplate: mapSource));

              bdp.regionTransfer = downloadableRegion.originalRegion;
              bdp.minZoom = downloadableRegion.minZoom;
              bdp.maxZoom = downloadableRegion.maxZoom;
              bdp.parallelThreads = downloadableRegion.parallelThreads;
              bdp.seaTileRemoval = downloadableRegion.seaTileRemoval;
              bdp.preventRedownload = downloadableRegion.preventRedownload;

              Navigator.of(context).pop();
              Navigator.of(context).popAndPushNamed('/');
              Navigator.of(context).pushNamed(
                '/download',
                arguments: {
                  'mcm': MapCachingManager(cacheDir, name),
                  'ignoreDownloadChecks': false,
                },
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Only foreground recovery downloading is supported in this example application'),
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_fix_high,
                  color: Colors.black,
                ),
                const SizedBox(width: 15),
                const VerticalDivider(
                  indent: 0,
                  endIndent: 0,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await StorageCachingTileProvider(
                            parentDirectory: cacheDir, _storeName: name)
                        .recoverDownload();
                    Navigator.of(context).pop();
                    Navigator.of(context).popAndPushNamed('/');
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
