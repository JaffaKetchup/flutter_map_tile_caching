import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_example/state/bulk_download_provider.dart';
import 'package:provider/provider.dart';

import '../../state/general_provider.dart';

class BackgroundDownload extends StatefulWidget {
  const BackgroundDownload({
    Key? key,
    required this.mcm,
    required this.contextOfPanel,
  }) : super(key: key);

  final BuildContext contextOfPanel;
  final MapCachingManager mcm;

  @override
  State<BackgroundDownload> createState() => _BackgroundDownloadState();
}

class _BackgroundDownloadState extends State<BackgroundDownload> {
  bool hasBeenGranted = false;

  Future<bool> checkIfGranted(BuildContext context) => hasBeenGranted
      ? Future.sync(() => true)
      : StorageCachingTileProvider.requestIgnoreBatteryOptimizations(
          context,
          requestIfDenied: false,
        );

  String? mapSource;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mapSource ??= context
        .read<GeneralProvider>()
        .persistent!
        .getString('${widget.mcm._storeName}: sourceURL');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkDownloadProvider>(
      builder: (context, bdp, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Background Download',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Whilst background downloading is not 100% reliable (due to differences between Android devices), this library tries to make it as easy as possible.\nTo do this, we need your permission to ignore battery optimisations. This may be marked as a hazardous permission, but it is needed to run a background task with minimal interruption by the operating system. You can proceed without this permission, but the download will be unstable.\nNote that this example does not consider device status before downloading - low battery level, for example, will not be caught.',
                ),
                const SizedBox(height: 10),
                FutureBuilder<bool>(
                  future: checkIfGranted(context),
                  builder: (context, granted) {
                    if (!granted.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (hasBeenGranted) {
                      return const OutlinedButton(
                        onPressed: null,
                        child: Text('Permission Granted'),
                      );
                    }

                    if (granted.data!) {
                      return const OutlinedButton(
                        onPressed: null,
                        child: Text('Permission Already Granted'),
                      );
                    }

                    return OutlinedButton(
                      onPressed: () async {
                        final bool granted = await StorageCachingTileProvider
                            .requestIgnoreBatteryOptimizations(context);
                        setState(() => hasBeenGranted = granted);
                      },
                      child: const Text('Grant Permission'),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(widget.contextOfPanel).pop();
                        Navigator.of(widget.contextOfPanel).pop();
                        Navigator.of(widget.contextOfPanel).pop();
                        bool started = false;

                        Future.delayed(const Duration(seconds: 3), () {
                          if (!started) {
                            StorageCachingTileProvider.fromMapCachingManager(
                                    widget.mcm)
                                .downloadRegionBackground(
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
                              useAltMethod: true,
                            );
                          }
                        });

                        StorageCachingTileProvider.fromMapCachingManager(
                                widget.mcm)
                            .downloadRegionBackground(
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
                          callback: ((dp) {
                            started = true;
                            return false;
                          }),
                        );
                      },
                      child: const Text('Start Download In Background'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(widget.contextOfPanel).pop();
                      },
                      child: const Text('Cancel'),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
