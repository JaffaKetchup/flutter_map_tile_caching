import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/bulk_download_provider.dart';
import '../../state/general_provider.dart';
import 'components/download_stats.dart';
import 'components/exit_dialog.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  MapCachingManager? mcm;
  StorageCachingTileProvider? tileProvider;
  Stream<DownloadProgress>? download;

  bool ignoreDownloadChecks = false;
  bool badBattery = false;
  bool badConnectivity = false;
  bool noInternet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    mcm ??= args['mcm'];
    ignoreDownloadChecks = args['ignoreDownloadChecks'];

    //mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager?;

    final String? mapSource = context
        .read<GeneralProvider>()
        .persistent!
        .getString('${mcm!.storeName}: sourceURL');

    final BulkDownloadProvider bdp = context.read<BulkDownloadProvider>();

    tileProvider ??= StorageCachingTileProvider.fromMapCachingManager(mcm!);
    download ??= tileProvider!
        .downloadRegion(
          bdp.region.toDownloadable(
            bdp.minZoom,
            bdp.maxZoom,
            TileLayerOptions(
                urlTemplate: mapSource ??
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            parallelThreads: bdp.parallelThreads,
            preventRedownload: bdp.preventRedownload,
            seaTileRemoval: bdp.seaTileRemoval,
          ),
          preDownloadChecksCallback: ignoreDownloadChecks
              ? null
              : (c, lvl, status) async {
                  badBattery = lvl! < 15 && status != ChargingStatus.Charging;
                  badConnectivity = c == ConnectivityResult.mobile;
                  noInternet = c == ConnectivityResult.none ||
                      c == ConnectivityResult.bluetooth;
                  return !(badBattery || badConnectivity || noInternet);
                },
        )
        .asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Use exit button to cancel download'),
        ));
        return false;
      },
      child: Consumer<BulkDownloadProvider>(
        builder: (context, bdp, _) {
          if (download == null) {
            return Container(color: Colors.white);
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Downloading...'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if ((await showDialog<bool>(
                        context: context,
                        builder: (context) => const ExitDialog(),
                      )) ??
                      false) {
                    tileProvider!.cancelDownload();
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FutureBuilder<bool>(
                  future: download!.isEmpty,
                  builder: (context, isEmpty) {
                    /*if (!isEmpty.hasData) {
                      return SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 56,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Downloading Failure',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'The first tile of the download failed, and we can\'t recover from that. Failures in later tiles are handled, but failures in the first tile are not handled in this example due to complications (can be handled in API).',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.popAndPushNamed(
                                  context,
                                  '/download',
                                  arguments: {
                                    'mcm': mcm,
                                    'ignoreDownloadChecks': false,
                                  },
                                );
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }*/

                    if (isEmpty.data ?? false) {
                      return SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.amber[700],
                              size: 56,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              badBattery
                                  ? 'Battery Level Low'
                                  : badConnectivity
                                      ? 'Connected via Cellular Data'
                                      : 'No Internet Connected',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              badBattery
                                  ? 'Please ensure your device has a battery level above 15% or is charging, then try again.'
                                  : badConnectivity
                                      ? 'You appear to be using cellular/mobile data, which might incur extra costs. Continue at your own risk.'
                                      : 'There appears to be no Internet connection. Continuing will fail all tiles.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.popAndPushNamed(
                                      context,
                                      '/download',
                                      arguments: {
                                        'mcm': mcm,
                                        'ignoreDownloadChecks': false,
                                      },
                                    );
                                  },
                                  child: const Text('Try Again'),
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: () {
                                    Navigator.popAndPushNamed(
                                      context,
                                      '/download',
                                      arguments: {
                                        'mcm': mcm,
                                        'ignoreDownloadChecks': true,
                                      },
                                    );
                                  },
                                  child: const Text('Force Download'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return DownloadStats(
                      mcm: mcm,
                      download: download,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
