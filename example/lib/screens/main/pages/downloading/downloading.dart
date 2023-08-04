import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../region_selection/state/region_selection_provider.dart';
import 'components/download_layout.dart';
import 'state/downloading_provider.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({super.key});

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Selector<RegionSelectionProvider, StoreDirectory?>(
                selector: (context, provider) => provider.selectedStore,
                builder: (context, selectedStore, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloading',
                      style: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Downloading To: ${selectedStore!.storeName}',
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: StreamBuilder<DownloadProgress>(
                    stream: context
                        .select<DownloadingProvider, Stream<DownloadProgress>?>(
                      (provider) => provider.downloadProgress,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.data == null) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Taking a while?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Please wait for the download to start...',
                              ),
                            ],
                          ),
                        );
                      }

                      final latestTileEvent = snapshot.data!.latestTileEvent;

                      if (latestTileEvent.result.category ==
                              TileEventResultCategory.failed &&
                          !latestTileEvent.isRepeat) {
                        context
                            .read<DownloadingProvider>()
                            .addFailedTile(latestTileEvent);
                      }

                      return DownloadLayout(
                        storeDirectory: context
                            .select<RegionSelectionProvider, StoreDirectory?>(
                          (provider) => provider.selectedStore,
                        )!,
                        download: snapshot.data!,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
